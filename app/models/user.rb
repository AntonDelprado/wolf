# == Schema Information
#
# Table name: users
#
#  id                  :integer         not null, primary key
#  name                :string(255)
#  email               :string(255)
#  handle              :string(255)
#  created_at          :datetime        not null
#  updated_at          :datetime        not null
#  password_digest     :string(255)
#  active_character_id :integer
#  character2_id       :integer
#  character3_id       :integer
#  active_campaign_id  :integer
#  campaign2_id        :integer
#  campaign3_id        :integer
#

class User < ActiveRecord::Base
	attr_accessible :email, :handle, :name, :password, :password_confirmation, :active_character, :character2_id, :character3_id, :active_campaign_id, :campaign2_id, :campaign3_id
	has_secure_password
	has_many :characters, dependent: :delete_all
	has_many :campaign_members
	has_many :campaigns, through: :campaign_members

	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
	validates :handle, presence: true, length: { maximum: 50 }
	validates :password, presence: true, length: { minimum: 6 }
	validates :password_confirmation, presence: true

	before_save { |user| user.email = email.downcase }

	def campaign_select
		campaigns.collect { |campaign| [campaign.name, campaign.id] }.unshift(['None', nil])
	end

	def active_characters
		@actives ||= [self.active_character_id, self.character2_id, self.character3_id].collect do |char_id|
			begin
				Character.find(char_id) unless char_id.nil?
			rescue ActiveRecord::RecordNotFound
			end
		end.compact
	end

	def active_character
		@active ||= Character.find(self.active_character_id) unless active_character_id.nil?
	end

	def push_active_character(character)
		if character.is_a? Character
			self.active_characters
			@actives.unshift character
			@actives.uniq! { |character| character.id }
			write_attribute(:character3_id, @actives[2].id) if @actives.count >= 3
			write_attribute(:character2_id, @actives[1].id) if @actives.count >= 2
			write_attribute(:active_character_id, @actives[0].id)
			self.save(validate: false)

			@actives = @active = nil # reset so they can be recalculated when needed.
		end
	end

	def active_campaigns
		@active_campaigns ||= [self.active_campaign_id, self.campaign2_id, self.campaign3_id].collect do |camp_id|
			begin
				Campaign.find(camp_id) unless camp_id.nil?
			rescue ActiveRecord::RecordNotFound
			end
		end.compact
	end

	def active_campaign
		@active_campaign ||= Campaign.find(self.active_campaign_id) unless active_campaign_id.nil?
	end

	def push_active_campaign(campaign)
		if campaign.is_a? Campaign
			self.active_campaigns
			@active_campaigns.unshift campaign
			@active_campaigns.uniq! { |campaign| campaign.id }
			write_attribute(:campaign3_id, @active_campaigns[2].id) if @active_campaigns.count >= 3
			write_attribute(:campaign2_id, @active_campaigns[1].id) if @active_campaigns.count >= 2
			write_attribute(:active_campaign_id, @active_campaigns[0].id)
			self.save(validate: false) # not supplying passwords so will not validate

			@active_campaigns = @active_campaign = nil
		end
	end
end
