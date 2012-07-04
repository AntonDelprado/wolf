# == Schema Information
#
# Table name: campaign_members
#
#  id          :integer         not null, primary key
#  campaign_id :integer
#  user_id     :integer
#  membership  :integer
#  created_at  :datetime        not null
#  updated_at  :datetime        not null
#

class CampaignMember < ActiveRecord::Base
	attr_accessible :campaign_id, :user_id, :membership
	belongs_to :user
	belongs_to :campaign

	MEMBERSHIP = 
	{
		none: 0,
		admin: 1,
		member: 2,
		invite: 3,
		request: 4,
		denied: 5,
	}

	validates :campaign_id, presence: true
	validates :user_id, presence: true
	validates :membership, presence: true, inclusion: MEMBERSHIP.keys

	def self.admin_of?(user, campaign)
		self.exists? campaign_id: campaign.id, user_id: user.id, membership: 1
	end

	def self.membership(mem)
		MEMBERSHIP[mem]
	end

	def membership
		MEMBERSHIP.invert[read_attribute :membership]
	end

	def membership=(value)
		write_attribute :membership, MEMBERSHIP[value]
	end

	def self.member_sql
		"membership IN (#{MEMBERSHIP[:member]},#{MEMBERSHIP[:admin]})"
	end

	def self.admin_sql
		"membership = #{MEMBERSHIP[:admin]}"
	end

	def self.request_sql
		"membership = #{MEMBERSHIP[:request]}"
	end

	def admin?
		1 == read_attribute(:membership)
	end

	def member?
		read_attribute(:membership) == 1 or read_attribute(:membership) == 2
	end
end
