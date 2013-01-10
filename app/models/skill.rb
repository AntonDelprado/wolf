# == Schema Information
#
# Table name: skills
#
#  id                :integer         not null, primary key
#  character_id      :integer
#  name              :string(255)
#  level             :integer
#  created_at        :datetime        not null
#  updated_at        :datetime        not null
#  required_skill_id :integer
#

include ApplicationHelper

class Skill < ActiveRecord::Base
	attr_accessible :character_id, :level, :name, :required_skill
	belongs_to :character, touch: true
	has_many :dependent_skills, dependent: :destroy, foreign_key: :required_skill_id, class_name: 'Skill'
	belongs_to :required_skill, class_name: 'Skill'

	validates :character_id, presence: true
	validates :level, presence: true, numericality: { greater_than: 0 }
	validates :name, presence: true

	BASE_SKILLS = %w[Endurance Sprint Observation Sense]
	SYNERGY_TAGS = {
		'Warrior' => 'warrior',
		'Rogue' => 'rogue',
		'Channeller' => 'channeller',
		'Mechanist' => 'mechanist',
		'Trickster' => 'trickster',
		'Battle Mage' => 'battle-mage',
		'Necromancer' => 'necromancer',
		'Lore' => 'lore',
		'No Class' => 'no-synergy',
		nil => 'no-synergy',
	}

	SYNERGIES_NAMES = ['Warrior', 'Rogue', 'Channeller', 'Mechanist', 'Trickster', 'Battle Mage', 'Necromancer', 'Lore', 'No Class']
	STATLESS = {
		name: 'Statless',
	}

	before_validation(on: :create) do
		# raise "raw = #{raw_data.count}"
		self.level = case name
		when 'Endurance' then self.character.str/2
		when 'Sprint' then self.character.dex/2
		when 'Observation' then self.character.int/2
		when 'Sense' then self.character.fai/2
		else 1
		end

		required_name = self.class.raw_data[self.name][:required_skill]
		if required_name
			self.required_skill = self.character.skill(required_name)
			self.required_skill ||= self.character.skills.create(name: required_name)
			self.required_skill.set_level(self.level+1) unless self.required_skill.level > self.level
		end
	end

	after_create do
		self.required_skill.dependent_skills << self if self.required_skill
	end

	before_destroy do
		self.dependent_skills.each { |skill| skill.destroy }
	end

	def self.statless
		STATLESS
	end

	def self.base_skills
		BASE_SKILLS
	end

	def self.synergy_css_for(synergy)
		SYNERGY_TAGS[synergy]
	end

	def self.synergy_names
		SYNERGY_TAGS.keys.compact
	end

	@@raw_data = nil

	def self.required_by(skill_name)
		required_by = []
		if skill_name == 'Statless'
			self.raw_data.each { |name, data| required_by << name if data[:stat].nil? }
		else
			self.raw_data.each { |name, data| required_by << name if data[:required_skill] == skill_name }
		end
		required_by
	end

	def self.required_size(skill_name)
		required_by = self.required_by(skill_name)
		return 1 if required_by.empty?
		length = -1
		required_by.each { |required| length += 1 + self.required_size(required) }
		return length
	end

	def self.required_row(skill_name, row_num)
		required_by = self.required_by(skill_name)
		if row_num == 0
			return [skill_name] if required_by.empty?
			return [skill_name].concat(self.required_row(required_by[0], 0))
		else
			child_num = 0
			while self.required_size(required_by[child_num])+1 <= row_num
				row_num -= self.required_size(required_by[child_num])+1
				child_num += 1
			end
			return [] if self.required_size(required_by[child_num]) == row_num
			return self.required_row(required_by[child_num], row_num)
		end
	end

	def self.every
		self.raw_data.collect { |name, data| self.new name: name unless name == 'statless' }.compact
	end

	def set_level(level)
		if level <= 0
			changed = [self.destroy.name]
		elsif self.level > level
			changed = [self.name]
			self.update_attribute(:level, level)
			self.dependent_skills.each { |skill| changed.concat skill.set_level(level-1) }
		elsif self.level < level
			changed = [self.name]
			self.update_attribute(:level, level)
			changed.concat(self.required_skill.set_level(level+1)) if self.required_skill
		else
			changed = []
		end

		return changed
	end

	def min_level
		return 1+dependent_skills.collect { |skill| skill.min_level }.max unless dependent_skills.empty?

		case name
		when 'Endurance' then self.character.str/2
		when 'Sprint' then self.character.dex/2
		when 'Observation' then self.character.int/2
		when 'Sense' then self.character.fai/2
		else 1
		end
	end

	def full_name
		return "#{self.name} / #{self.class.raw_data[self.name][:name_inv]}" if self.class.raw_data[self.name].has_key? :name_inv
		return self.name
	end

	def inv_name
		self.class.raw_data[self.name][:name_inv]
	end

	def has_synergy?
		not synergy_name.nil?
	end

	def synergy_name
		self.class.raw_data[self.name][:synergy]
	end

	def synergy_css(prefix="")
		"#{prefix}#{SYNERGY_TAGS[self.synergy_name]}"
	end

	def name_tag(prefix)
		"#{prefix}_#{self.name.gsub(' ', '_')}"
	end

	def spell
		self.class.raw_data[self.name][:spell]
	end

	def cost
		self.class.raw_data[self.name][:cost]
	end

	def stat
		self.class.raw_data[self.name][:stat]
	end

	def effects
		self.class.raw_data[self.name][:effects]
	end

	def quick
		self.class.raw_data[self.name][:quick]
	end

	def text
		self.class.raw_data[self.name][:text]
	end

	def icons
		icon_list = []

		case self.class.raw_data[self.name][:stat]
		when 'Str' then icon_list << '/assets/str.png'
		when 'Dex' then icon_list << '/assets/dex.png'
		when 'Int' then icon_list << '/assets/int.png'
		when 'Fai' then icon_list << '/assets/fai.png'
		end

		icon_list << '/assets/divisible.png' if self.divisible?
		icon_list << '/assets/invertible.png' if self.invertible?
		icon_list << '/assets/defend.png' if self.defend?
		icon_list << '/assets/attack.png' if self.attack? && self.melee?
		icon_list << '/assets/ranged.png' if self.attack? && self.ranged?

		return icon_list
	end

	def attack?
		self.class.raw_data[self.name][:attack]
	end

	def ranged?
		self.class.raw_data[self.name][:ranged]
	end

	def melee?
		self.class.raw_data[self.name][:melee]
	end

	def defend?
		self.class.raw_data[self.name][:defend]
	end

	def invertible?
		self.class.raw_data[self.name][:invertible]
	end

	def divisible?
		self.class.raw_data[self.name][:divisible]
	end
	
	private

	# acquire all the private data from 'skills.xml'
	def self.raw_data
		if @@raw_data.nil?
			@@raw_data = {}
			XML::Parser.file('app/data/skills.xml').parse.root.find('Skill').each do |skill_xml|
				skill = {}
				skill_xml.find('Name').each do |name|
					if skill[:name]
						skill[:name_inv] = name.content
					else
						skill[:name] = name.content
					end
				end

				skill[:stat] = skill_xml.find_first('Stat').content if skill_xml.find_first('Stat')
				skill[:cost] = skill_xml.find_first('Cost').content.to_i
				skill[:synergy] = skill_xml.find_first('Synergy').content if skill_xml.find_first('Synergy')
				skill[:synergy_css] = SYNERGY_TAGS[skill[:synergy]]
				skill[:spell] = skill_xml.find_first('Spell').content if skill_xml.find_first('Spell')
				skill[:required_skill] = skill_xml.find_first('Require').content if skill_xml.find_first('Require')

				skill[:required_skill] ||= case skill[:stat]
				when 'Str' then 'Endurance'
				when 'Dex' then 'Sprint'
				when 'Int' then 'Observation'
				when 'Fai' then 'Sense'
				end unless skill[:stat].nil? or BASE_SKILLS.include? skill[:name]

				skill[:invertible] = !skill_xml.find_first('Invert').nil?
				skill[:divisible] = !skill_xml.find_first('Divide').nil?

				skill[:text] = skill_xml.find_first('Text')

				skill[:effects] = []
				skill_xml.find('Effect').each do |effect_xml|
					effect = {}

					effect[:quick] = effect_xml.find_first('Quick')
					effect[:mana] = effect_xml.find_first('Mana').content.to_s if effect_xml.find_first('Mana')
					effect[:power] = effect_xml.find_first('Power') if effect_xml.find_first('Power')

					case effect_xml.find_first('Action').content.downcase
					when 'major' then effect[:action] = :major_action
					when 'minor' then effect[:action] = :minor_action
					when 'attack' 
						effect[:action] = :attack_action
						skill[:attack] = true
						skill[:ranged] = (effect_xml.find_first('Action')['type'] != 'melee')
						skill[:melee] = (effect_xml.find_first('Action')['type'] != 'ranged')
					when 'defend'
						effect[:action] = :defend_action
						skill[:defend] = true
					end if effect_xml.find_first('Action')

					skill[:effects] << effect
				end

				@@raw_data[skill[:name]] = skill
			end
		end
		@@raw_data
	end
end
