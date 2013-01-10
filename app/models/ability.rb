# == Schema Information
#
# Table name: abilities
#
#  id           :integer         not null, primary key
#  character_id :integer
#  name         :string(255)
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#

class Ability < ActiveRecord::Base
	attr_accessible :character_id, :name
	belongs_to :character, touch: true

	validates :character_id, presence: true
	validates :name, presence: true

	@@raw_data = nil

	def self.every
		self.raw_data.collect { |name, data| self.new name: name }
	end

	def has_synergy?
		not self.synergy_name.nil?
	end

	def synergy_name
		self.class.raw_data[self.name][:synergy]
	end

	def synergy_css(prefix="")
		"#{prefix}#{Skill.synergy_css_for self.synergy_name}"
	end

	def name_tag(prefix)
		"#{prefix}_#{self.name.gsub(' ', '_')}"
	end

	def requirements
		self.class.raw_data[self.name][:require]
	end

	def quick
		self.class.raw_data[self.name][:quick]
	end

	def text
		self.class.raw_data[self.name][:text]
	end

	def requires
		unless requirements.nil?
			required = []
			requirements.each do |type, value|
				required << case type
				when :xp then "#{value} XP Spent"
				when :spell_xp then "#{value} XP Spent in Spells"
				when :ability then value
				else value
				end
			end
			return required.join(', ')
		end
	end

	private

	def self.raw_data
		if @@raw_data.nil?
			@@raw_data = {}
			XML::Parser.file('app/data/abilities.xml').parse.root.find('Ability').each do |ability_xml|
				ability = {}

				ability[:name] = ability_xml.find_first('Name').content
				ability[:text] = ability_xml.find_first('Text')
				ability[:quick] = ability_xml.find_first('Quick')
				ability[:synergy] = ability_xml.find_first('Synergy').content if ability_xml.find_first('Synergy')
				ability[:synergy_css] = Skill.synergy_css_for(ability[:synergy]) if ability[:synergy]

				ability_xml.find_first('Require').children.each do |require_xml|
					require_hash = {}
					case require_xml.name
					when 'Str' then require_hash[:str] = require_xml.content.to_i
					when 'Dex' then require_hash[:dex] = require_xml.content.to_i
					when 'Int' then require_hash[:int] = require_xml.content.to_i
					when 'Fai' then require_hash[:fai] = require_xml.content.to_i
					when 'XP'
						if require_xml.attributes['type'] == 'Spell'
							require_hash[:spell_xp] = require_xml.content.to_i
						else
							require_hash[:xp] = require_xml.content.to_i
						end
					when 'Ability' then require_hash[:ability] = require_xml.content
					when 'Race' then require_hash[:race] = require_xml.content
					end
					ability[:require] = require_hash
				end if ability_xml.find_first('Require')

				@@raw_data[ability[:name]] = ability
			end
		end

		@@raw_data
	end

end
