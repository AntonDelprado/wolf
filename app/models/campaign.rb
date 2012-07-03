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

	def reload(options = nil)
		super
		@characters = @members = @requests = nil
	end

	def self.visibility(vis)
		VISIBILITY[vis]
	end

	def characters
		@characters ||= Character.find_all_by_campaign_id(self.id)
	end

	def add_member(member, membership_type=:member)
		case member
		when User then new_membership = CampaignMember.new campaign_id: self.id, user_id: member.id
		when Integer then new_membership = CampaignMember.new campaign_id: self.id, user_id: member
		end

		new_membership.membership = membership_type
		new_membership.save

		@members = nil if membership_type == :member or membership_type == :admin # clear cached members
	end

	def members
		@members ||= CampaignMember.find_all_by_campaign_id(self.id).collect { |membership| membership.member? ? User.find(membership.user_id) : nil }.compact
	end

	def requests
		@requests ||= CampaignMember.find_all_by_campaign_id_and_membership(self.id, CampaignMember.membership(:request))
	end

	def has_member?(member)
		case member
		when User then membership = CampaignMember.find_by_campaign_id_and_user_id(self.id, member.id)
		when Integer then membership = CampaignMember.find_by_campaign_id_and_user_id(self.id, member)
		else return false
		end

		return (!membership.nil? and membership.member?)
	end

	def has_admin?(member)
		case member
		when User then return CampaignMember.exists? campaign_id: self.id, user_id: member.id, membership: CampaignMember.membership(:admin)
		when Integer then return CampaignMember.exists? campaign_id: self.id, user_id: member, membership: CampaignMember.membership(:admin)
		else return false
		end
	end

	def member_type(member)
		case member
		when User then membership = CampaignMember.find_by_campaign_id_and_user_id(self.id, member.id)
		when Integer then membership = CampaignMember.find_by_campaign_id_and_user_id(self.id, member)
		else return nil
		end

		membership.membership unless membership.nil?
	end

	def membership_for(member)
		case member
		when User
			( CampaignMember.find_by_campaign_id_and_user_id(self.id, member.id) ||
				CampaignMember.new(campaign_id: self.id, user_id: member.id, membership: :none) )
	
		when Integer
			( CampaignMember.find_by_campaign_id_and_user_id(self.id, member) ||
				CampaignMember.new(campaign_id: self.id, user_id: member, membership: :none) )
		end
	end

	def visibility=(vis)
		write_attribute :visibility, VISIBILITY[vis]
	end

	def visibility
		VISIBILITY.invert[read_attribute :visibility]
	end

	def visible_to?(user)
		return true if self.visibility == :open

		case user
		when User then type = CampaignMember.find_by_campaign_id_and_user_id(self.id, user.id)
		when Integer then type = CampaignMember.find_by_campaign_id_and_user_id(self.id, user)
		else return false
		end

		return (type and [:member, :admin, :invite].include? type.membership)
	end

	def open?
		self.visibility == :open
	end
end
