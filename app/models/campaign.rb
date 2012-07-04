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
	has_many :characters
	has_many :campaign_members
	has_many :users, through: :campaign_members
	has_many :members, through: :campaign_members, source: :user, conditions: CampaignMember.member_sql
	has_many :admins, through: :campaign_members, source: :user, conditions: CampaignMember.admin_sql

	VISIBILITY = { :open => 1, :closed => 0 }

	validates :name, presence: true
	validates :visibility, inclusion: VISIBILITY.keys

	def self.visibility(vis)
		VISIBILITY[vis]
	end

	def add_member(member, membership_type=:member)
		member_id = (member.is_a?(User) ? member.id : member.to_i)
		self.campaign_members.create user_id: member_id, membership: membership_type
	end

	def has_member?(member)
		member_id = (member.is_a?(User) ? member.id : member.to_i)
		self.members.exists? id: member_id
	end

	def has_admin?(member)
		member_id = (member.is_a?(User) ? member.id : member.to_i)
		self.admins.exists? id: member_id
	end

	def member_type(member)
		member_id = (member.is_a?(User) ? member.id : member.to_i)
		membership = self.campaign_members.find_by_user_id(member_id)
		if membership
			return membership.membership
		else
			return nil
		end
	end

	def membership_for(member)
		member_id = (member.is_a?(User) ? member.id : member.to_i)
		self.campaign_members.find_by_user_id(member_id) || self.campaign_members.build(user_id: member_id, membership: :none)
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
		when User then type = self.campaign_members.find_by_user_id(user.id)
		when Integer then type = self.campaign_members.find_by_user_id(user)
		else return false
		end

		return (type and [:member, :admin, :invite].include? type.membership)
	end

	def open?
		self.visibility == :open
	end
end
