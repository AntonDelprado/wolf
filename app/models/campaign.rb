# == Schema Information
#
# Table name: campaigns
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  description :text
#  created_at  :datetime        not null
#  updated_at  :datetime        not null
#  visibility  :integer(255)
#

class Campaign < ActiveRecord::Base
	attr_accessible :name, :description, :visibility

	VISIBILITY = { :open => 1, :closed => 0 }

	validates :name, presence: true
	validates :visibility, inclusion: VISIBILITY.keys

	def self.visibility(vis)
		VISIBILITY[vis]
	end

	def characters
		@characters ||= Character.find_all_by_campaign_id(self.id)
	end

	def add_member(member, membership_type=:member)
		if member.is_a? User
			new_membership = CampaignMember.new campaign_id: self.id, user_id: member.id
			new_membership.membership = membership_type
			new_membership.save

			@members = nil # clear cached members
		end
	end

	def members
		@members ||= CampaignMember.find_all_by_campaign_id(self.id).collect { |membership| membership.member? ? User.find(membership.user_id) : nil }.compact
	end

	def requests
		@requests ||= CampaignMember.find_all_by_campaign_id_and_membership(self.id, CampaignMember.membership(:request))
	end

	def has_member?(member)
		if member.is_a? User
			membership = CampaignMember.find_by_campaign_id_and_user_id(self.id, member.id)
			!membership.nil? and membership.member?
		end
	end

	def has_admin?(member)
		CampaignMember.exists?(campaign_id: self.id, user_id: member.id, membership: 1) if member.is_a? User
	end

	def member_type(member)
		CampaignMember.find_by_campaign_id_and_user_id(self.id, member.id).membership if member.is_a? User
	end

	def visibility=(vis)
		write_attribute :visibility, VISIBILITY[vis]
	end

	def visibility
		VISIBILITY.invert[read_attribute :visibility]
	end

	def open?
		self.visibility == :open
	end
end
