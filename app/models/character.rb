# == Schema Information
#
# Table name: characters
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  str         :integer
#  dex         :integer
#  int         :integer
#  fai         :integer
#  created_at  :datetime        not null
#  updated_at  :datetime        not null
#  race        :string(255)
#  user_id     :integer
#  campaign_id :integer
#  privacy     :integer
#

include ApplicationHelper
include SessionsHelper

class Character < ActiveRecord::Base
	attr_accessible :dex, :fai, :int, :name, :race, :str, :user_id, :privacy, :campaign_id
	has_many :skills, dependent: :delete_all, uniq: true, class_name: 'Skill'
	has_many :abilities, dependent: :delete_all, uniq: true, class_name: 'Ability'
	has_many :items, dependent: :delete_all, uniq: true, class_name: 'Equipment'
	belongs_to :campaign
	belongs_to :user

	PRIVACY = { public: 0, campaign: 1, private: 2 }

	WOLF_STATS = [[12,4,4,4], [10,10,4,4], [10,8,6,4], [8,8,8,6]]
	DWARF_STATS = WOLF_STATS
	GOBLIN_STATS = [[8,6,4,4], [6,6,6,6]]
	VAMPIRE_STATS = [[12,12,12,4]]
	NIL_STATS = [[0,0,0,0]]

	BASE_STATS = {
		'Wolf' => WOLF_STATS,
		'Dwarf' => DWARF_STATS,
		'Goblin' => GOBLIN_STATS,
		'Vampire' => VAMPIRE_STATS,
	}

	validates :name, presence: true, length: { maximum: 100 }
	validates :race, presence: true, inclusion: BASE_STATS.keys
	validates :str, presence: true, inclusion: [4,6,8,10,12]
	validates :dex, presence: true, inclusion: [4,6,8,10,12]
	validates :int, presence: true, inclusion: [4,6,8,10,12]
	validates :fai, presence: true, inclusion: [4,6,8,10,12]
	validates :user_id, presence: true
	validates :privacy, presence: true, inclusion: PRIVACY.keys

	after_create do
		update_base_skills
		if self.race == 'Vampire'
			self.add_ability 'Atheist'
			self.add_ability 'Literate'
		end
	end

	def self.privacy(priv)
		PRIVACY[priv.to_sym]
	end

	def self.join_stats(stats)
		return "#{stats[0]} Str, #{stats[1]} Dex, #{stats[2]} Int, #{stats[3]} Fai"
	end

	def self.import_xml(xml_root, user_id)
		begin
			character = Character.new user_id: user_id, privacy: :public

			character.name = xml_root.find_first('Name').content
			character.race = xml_root.find_first('Race').content

			stats_xml = xml_root.find_first('Stats')
			character.str = stats_xml.find_first('Strength').content.to_i
			character.dex = stats_xml.find_first('Dexterity').content.to_i
			character.int = stats_xml.find_first('Intelligence').content.to_i
			character.fai = stats_xml.find_first('Faith').content.to_i

			raise 'Not Saved' unless character.save

			character.update_base_skills

			xml_root.find_first('Skills').find('Skill').each do |skill_node|
				character.add_skill(skill_node.content)
				character.skill(skill_node.content).set_level(skill_node.attributes['level'].to_i)
			end

			xml_root.find_first('Abilities').find('Ability').each do |ability_node|
				character.add_ability ability_node.content
			end

			items_xml = xml_root.find_first('Items')
			character.equip(primary: items_xml.find_first('Primary').content) if items_xml.find_first('Primary')
			character.equip(off_hand: items_xml.find_first('OffHand').content) if items_xml.find_first('OffHand')
			character.equip(armour: items_xml.find_first('Armour').content) if items_xml.find_first('Armour')

			return character
		rescue NoMethodError
			character.delete
			return nil
		end
	end

	def export_xml(file_type = :xml)
		case file_type
		when :xml
			doc = XML::Document.new()
			doc.root = XML::Node.new('Character')

			# Character and race
			doc.root << (XML::Node.new('Name') << XML::Node.new_text(self.name))
			doc.root << (XML::Node.new('Race') << XML::Node.new_text(self.race))

			# Stats
			stats_node = XML::Node.new('Stats')
			stats_node << (XML::Node.new('Strength') << XML::Node.new_text(self.str.to_s))
			stats_node << (XML::Node.new('Dexterity') << XML::Node.new_text(self.dex.to_s))
			stats_node << (XML::Node.new('Intelligence') << XML::Node.new_text(self.int.to_s))
			stats_node << (XML::Node.new('Faith') << XML::Node.new_text(self.fai.to_s))

			# Skills
			skills_node = XML::Node.new('Skills')
			self.skills.each do |skill|
				skill_node = XML::Node.new('Skill')
				skill_node.attributes['level'] = skill.level
				skill_node << XML::Node.new_text(skill.name)
				skills_node << skill_node
			end

			# Abilities
			abilities_node = XML::Node.new('Abilities')
			self.abilities.each do |ability|
				abilities_node << (XML::Node.new('Ability') << XML::Node.new_text(ability.name))
			end

			# Items
			items_node = XML::Node.new('Items')
			items_node << (XML::Node.new('Primary') << XML::Node.new_text(self.primary.name)) if self.primary_equiped?
			items_node << (XML::Node.new('OffHand') << XML::Node.new_text(self.off_hand.name)) if self.off_hand_equiped?
			items_node << (XML::Node.new('Armour') << XML::Node.new_text(self.armour.name)) if self.armour_equiped?

			doc.root << stats_node << skills_node << abilities_node << items_node

			return doc
		end
	end

	def in_campaign?
		not campaign_id.nil?
	end

	def public?
		self.privacy == :public
	end

	def privacy=(priv)
		write_attribute :privacy, PRIVACY[priv.to_sym]
	end

	def privacy
		PRIVACY.invert[read_attribute :privacy]
	end

	def visible_to?(user)
		return true if self.user_id == (user.is_a?(User) ? user.id : user.to_i)

		case self.privacy
		when :public then true
		when :campaign then self.in_campaign? and self.campaign.has_member? user
		when :private then false
		end
	end

	def stats
		[self.str, self.dex, self.int, self.fai]
	end

	def str_mod
		self.items.reduce(0) { |sum, item| sum + item.str_mod.to_i }
	end

	# stats need to be reset if changing races, except dwarf <-> wolf
	def race=(new_race)
		self.str, self.dex, self.int, self.fai = BASE_STATS[new_race][0] unless BASE_STATS[new_race].include? self.stats.sort.reverse
		write_attribute :race, new_race
	end

	def dex_mod
		self.items.reduce(0) { |sum, item| sum + item.dex_mod.to_i }
	end

	def int_mod
		self.items.reduce(0) { |sum, item| sum + item.int_mod.to_i }
	end

	def fai_mod
		self.items.reduce(0) { |sum, item| sum + item.fai_mod.to_i }
	end

	def str_final
		return self.str + 2*self.str_mod
	end

	def dex_final
		return self.dex + 2*self.dex_mod
	end

	def int_final
		return self.int + 2*self.int_mod
	end

	def fai_final
		return self.fai + 2*self.fai_mod
	end

	# Set all base skills to their minimum level
	def update_base_skills
		self.add_skill 'Endurance'
		self.add_skill 'Sprint'
		self.add_skill 'Observation'
		self.add_skill 'Sense'
	end

	def has_skill?(skill_name)
		self.skills.exists? name: skill_name
	end

	def skill(skill_name)
		self.skills.find_by_name skill_name
	end

	def has_ability?(ability_name)
		self.abilities.find_by_name ability_name
	end

	def add_skill(skill_name)
		self.skills.create(name: skill_name) unless self.has_skill? skill_name
	end

	# Remove a skill, plus dependants, and return an array of the skills that were removed
	def remove_skill(skill_name)
		self.skill(skill_name).destroy if self.skill(skill_name)
	end

	def add_ability(ability_name)
		self.abilities.create name: ability_name unless self.has_ability? ability_name
	end

	def remove_ability(ability_name)
		self.abilities.find_by_name(ability_name).delete
	end

	def can_add_skill?(skill_name)
		# cannot add skill twice
		return false if self.has_skill? skill_name
		# can only add 'will of' if 'follower of'
		return self.has_ability?(skill_name.sub('Will of', 'Follower of')) if skill_name[0..7].eql? 'Will of'
		# otherwise okay
		return true
	end

	def can_add_skills
		Skill.raw_data.collect { |skill_name, skill_data| self.can_add_skill?(skill_name) ? Skill.new(name: skill_name) : nil }.compact
	end

	def can_add_ability?(ability_name)
		# cannot add ability twice
		return false if self.has_ability? ability_name
		# cannot follow two gods
		return false if self.follower? and ability_name[0..8].eql? 'Follower'
		# otherwise needs to pass ability requirements
		return self.pass_requirements? Ability.raw_data[ability_name][:requirements]
	end

	def can_add_abilities
		Ability.raw_data.collect { |ability_name, ability_data| self.can_add_ability?(ability_name) ? Ability.new(name: ability_name) : nil }.compact
	end

	def follower_of
		self.abilities.each { |ability| return ability[:name].sub('Follower of ', '') if ability[:name][0..8] == 'Follower' }
		return nil
	end

	def follower?
		not self.abilities.detect { |ability_name| ability_name[0..8] == 'Follower' }.nil?
	end

	def primary
		Equipment.find_by_character_id_and_slot(self.id, 'Primary')
	end

	def primary_equiped?
		Equipment.exists? character_id: self.id, slot: 'Primary'
	end

	def off_hand
		Equipment.find_by_character_id_and_slot(self.id, 'Off Hand')
	end

	def off_hand_equiped?
		Equipment.exists? character_id: self.id, slot: 'Off Hand'
	end

	def armour
		Equipment.find_by_character_id_and_slot(self.id, 'Armour')
	end

	def armour_equiped?
		Equipment.exists? character_id: self.id, slot: 'Armour'
	end

	def items
		Equipment.find_all_by_character_id(self.id)
	end

	def unequip(slot)
		allthings = Equipment.find_all_by_character_id_and_slot(self.id,slot)
		allthings.each { |thing| thing.delete } if allthings
		# self.items.find_all_by_slot(slot).try(:delete)
	end

	def equip(equipment)
		equiped = []

		equipment.each do |slot, name|
			case slot
			when :primary
				if name == 'None'
					self.unequip('Primary')
				else
					Equipment.equip(self, 'Primary', name)
					equiped << name
				end

			when :off_hand
				if name == 'None'
					self.unequip('Off Hand')
				else
					Equipment.equip(self, 'Off Hand', name)
					equiped << name
				end

			when :armour
				if name == 'Cloth'
					self.unequip('Armour')
				else
					Equipment.equip(self, 'Armour', name)
					equiped << name
				end
			end unless name.nil?
		end

		return equiped
	end

	def can_equip(slot)
		case slot
		when :primary
			return Equipment.weapons.select { |weapon| self.pass_requirements? weapon.requirements }.collect { |weapon| weapon.name }.unshift('None')
		when :off_hand
			if self.has_ability? 'Ambidextrous'
				if self.has_ability? 'Weapons: Large'
					off_hand_equip = Equipment.weapons.select { |weapon| self.pass_requirements? weapon.requirements }
				else
					off_hand_equip = Equipment.weapons.select { |weapon| weapon.one_handed? and self.pass_requirements? weapon.requirements }
				end
			else
				off_hand_equip = []
			end
			Equipment.shields.each { |shield| off_hand_equip << shield if self.pass_requirements? shield.requirements }
			return off_hand_equip.collect { |item| item.name }.unshift('None')
		when :armour
			return Equipment.armours.select { |armour| self.pass_requirements? armour.requirements }.collect { |armour| armour.name }
		end
	end

	def synergies
		if @synergies.nil?
			bonus_remaining = true
			synergies = {}
			Skill.synergy_names.each { |name| synergies[name] = { level: 0, spent: 0, css_class: "name-#{Skill.synergy_css_for name}" } }

			self.skills.each do |skill|
				synergies[skill.synergy_name][:level] += skill.level if skill.has_synergy?
				synergies['Lore'][:level] += skill.level if skill.spell
			end

			if race == 'Goblin'
				synergies.each { |synergy_name, synergy| synergy[:level] /= 6 }
			else
				synergies.each { |synergy_name, synergy| synergy[:level] /= 10 }
			end

			self.abilities.each do |ability|
				if ability.has_synergy?
					if synergies[ability.synergy_name][:level] < synergies[ability.synergy_name][:spent]+2
						bonus_remaining ? bonus_remaining = false : synergies['No Class'][:spent] += 3
					else
						synergies[ability.synergy_name][:spent] += 2
					end
				else
					synergies['No Class'][:spent] += 2
				end
			end

			spent = 0
			synergies.each do |synergy_name, synergy|
				next if synergy_name.eql? 'No Class'
				remaining = synergy[:level] - synergy[:spent]
				spent += remaining
				synergy[:remaining] = remaining
			end
			synergies['No Class'][:remaining] = spent - synergies['No Class'][:spent]

			if synergies['No Class'][:remaining] < 0 and bonus_remaining
				bonus_remaining = false
				synergies['No Class'][:remaining] += 2
			end

			@synergy_bonus = bonus_remaining
			@synergies = synergies.reject { |synergy_name, synergy| synergy_name != 'No Class' and synergy[:level].zero? and synergy[:spent].zero? }
		end
		@synergies
	end

	def has_synergy?(synergy_name)
		self.synergies.has_key? synergy_name
	end

	def synergy_bonus
		self.synergies # ensure that synergies have been created
		@synergy_bonus
	end

	# index1 represents which ba
	def base_stats(index_base = nil, index_raw = nil)
		return BASE_STATS[self.race] if index_base.nil?
		if self.race == 'Vampire'
			return [[12,12,12,4]] if index_raw.nil?
			return [12,12,12,4]
		else
			return BASE_STATS[self.race][index_base].permutation.to_a.uniq if index_raw.nil?
			return BASE_STATS[self.race][index_base].permutation.to_a.uniq[index_raw]
		end
	end

	def parse_effect_xml(skill, effect_xml, raw)
		return effect_xml.content if effect_xml.find_first('skill').nil?

		total = effect_xml.attributes['add'].to_i
		effect_xml.find('skill').each { |skill_xml| total += self.skill(skill_xml.content).level if self.has_skill? skill_xml.content }
		total += self.synergies[skill.synergy_name][:level] if skill.has_synergy? and self.has_synergy? skill.synergy_name

		if skill.spell and self.follower?
			god = self.follower_of
			if god == "Travaer"
				total += (skill.invertible?) ? 1 : -1
			else
				total += (skill.spell == god) ? 2 : -1
			end
		end
		total += self.weapon_bonus if effect_xml.attributes['weapon']
		self.items.each { |item| total += item.skill_bonus(skill.name).to_i }
		total *= effect_xml.attributes['times'].to_f if effect_xml.attributes['times']
		total = total.floor

		unless effect_xml.attributes['type'] == 'roll'
			return total.to_i if raw
			return total.to_i.to_s
		end

		case skill.stat
		when 'Str' then dice_type = self.str_final
		when 'Dex' then dice_type = self.dex_final
		when 'Int' then dice_type = self.int_final
		when 'Fai' then dice_type = self.fai_final
		else dice_type = 0
		end

		return [total.to_i, dice_type] if raw
		return "<span onClick='roll(#{total.to_i}, #{dice_type})'>#{total.to_i}d#{dice_type}</span>".html_safe
	end

	def power(skill, effect, raw=false)
		parse_effect_xml(skill, effect[:power], raw) if effect[:power]
	end

	def duration(skill, effect, raw=false)
		parse_effect_xml(skill, effect[:duration], raw) if effect[:duration]
	end

	def roll(skill_name)
		skill = self.skills.find_by_name(skill_name)
		skill ||= Skill.new name: skill_name, level: 0

		dice = self.power(skill, skill.effects[0], true)
		return dice unless dice.is_a? Array
		return (1..dice[0]).reduce(0) { |total, index| total + (rand(dice[1])+1 >= 4 ? 1 : 0) }
	end

	def initiative
		self.roll('Initiative')
	end

	def stats_options(index = nil)
		return self.base_stats.each_with_index.collect { |stat, index| [stat.join(", "), index]} if index.nil?
		return self.base_stats[index].permutation.to_a.uniq.each_with_index.collect { |stat, index| [self.class.join_stats(stat), index]}
	end

	def stats_selected(option_index = nil)
		if option_index.nil?
			sorted_stats = self.stats.sort.reverse
			self.base_stats.each_with_index do |stat, index|
				return index if sorted_stats == stat
			end
			return nil
		else
			self.base_stats[option_index].permutation.to_a.uniq.each_with_index do |stat, index|
				return index if stat == self.stats
			end
			return nil
		end
	end

	def xp(type = nil)
		spent_xp = 0
		self.skills.each { |skill| spent_xp += skill.cost * skill.level unless type == :spell and skill.spell.nil? }
		return spent_xp
	end

	def hp_max
		extra_hp = self.has_skill?('Extra HP') ? self.skill('Extra HP').level : 0
		warrior = self.has_synergy?('Warrior') ? self.synergies['Warrior'][:level] : 0

		return self.str + self.dex + 3*(extra_hp + warrior)
	end

	def hp_rate
		regen = self.has_skill?('Regenerate') ? self.skill('Regenerate').level : 0
		warrior = self.has_synergy?('Warrior') ? self.synergies['Warrior'][:level] : 0

		return (0.5 * (regen+warrior)).floor - 5
	end

	def hp_time
		if self.hp_rate >= 0
			seconds = 10*self.hp_max/(1+self.hp_rate)
		else
			seconds = 10*self.hp_max*(2**-self.hp_rate).to_i
		end

		return "#{seconds} sec" if seconds < 60
		return "#{(seconds/60.0).round(1)} min" if seconds < 3600
		return "#{(seconds/3600.0).round(1)} hrs"
	end

	def mp_max
		extra_mp = self.has_skill?('Extra MP') ? self.skill('Extra MP').level : 0
		lore = self.has_synergy?('Lore') ? self.synergies['Lore'][:level] : 0

		return self.int + self.fai + 3*(extra_mp + lore)
	end

	def mp_rate
		refresh = self.has_skill?('Refresh') ? self.skill('Refresh').level : 0
		lore = self.has_synergy?('Lore') ? self.synergies['Lore'][:level] : 0

		return (0.5 * (refresh+lore)).floor - 5
	end

	def mp_time
		if self.mp_rate >= 0
			seconds = 10*self.mp_max/(1+self.mp_rate)
		else
			seconds = 10*self.mp_max*(2**-self.mp_rate).to_i
		end

		return "#{seconds} sec" if seconds < 60
		return "#{(seconds/60.0).round(1)} min" if seconds < 3600
		return "#{(seconds/3600.0).round(1)} hrs"
	end

	def damage_reduction
		self.items.reduce(0) { |dr, item| dr + item.dr.to_i }
	end

	def weapon_bonus
		self.items.reduce(0) { |bonus, item| bonus + item.bonus.to_i }
	end

	def speed
		speed_result = result_level(self.skill('Sprint').level)*2
		self.items.each { |item| speed_result += item.dex_mod if item.armour? }
		return speed_result
	end

	def pass_requirements?(requirements)
		return true if requirements.nil?
		requirements.all? do |type, value|
			case type
			when :str then self.str >= value
			when :dex then self.dex >= value
			when :int then self.int >= value
			when :fai then self.fai >= value
			when :xp then self.xp >= value
			when :spell_xp then self.xp :spell >= value
			when :abilities then value.all? { |ability_name| self.has_ability? ability_name }
			end
		end
	end

	def fail_requirements(requirements)
		failures = []
		requirements.each do |type, value|
			case type
			when :str		then failures << "Need #{value} Strength, only have #{self.str}"					if self.str < value
			when :dex		then failures << "Need #{value} Dexterity, only have #{self.dex}"					if self.dex < value
			when :int		then failures << "Need #{value} Intelligence, only have #{self.int}"				if self.int < value
			when :fai		then failures << "Need #{value} Faith, only have #{self.fai}"						if self.fai < value
			when :xp		then failures << "Need #{value} Spent XP, only have #{self.xp}"						if self.xp < value
			when :spell_xp	then failures << "Need #{value} Spent XP in Spells, only have #{self.xp :spell}"	if self.xp(:spell) < value
			when :ability	then failures << "Need to purchase '#{value}'"										unless self.has_ability? value
			end
		end unless requirements.nil?
		failures
	end

	def error_messages
		if self.race.nil? # if race is unset this is a 'new' action
			[]
		else
			errors = []

			errors << "Overspent Abilities by #{-self.synergies['No Class'][:remaining]} Points." if self.synergies['No Class'][:remaining] < 0

			errors << "Invalid Stats" unless BASE_STATS[self.race].include? self.stats.sort.reverse

			errors << "May Only Follow One God" if self.abilities.select{ |ability| ability[:name][0..8] == "Follower" }.count > 1

			self.skills.each do |skill|
				if skill.name[0..7].eql? 'Will of' and self.follower_of != skill.name.sub('Will of','')
					errors << "Need to be a follower of '#{skill.name.sub('Will of','')}' to user '#{skill.name}'"
				end
			end

			errors << "Only Wolves and Vampires may use 'Devour'" if self.has_skill?('Devour') and %[Goblin Dwarf].include? self.race


			self.abilities.each do |ability|
				self.fail_requirements(ability.requirements).each do |failure|
					errors << "'#{ability.name}': #{failure}"
				end
			end

			self.items.each do |item|
				case item.weapon_class
				when 'Ranged' then errors << 'Need to train in Ranged Weapons' unless self.has_ability? 'Weapons: Ranged'
				when 'Medium', 'Large' then errors << "Need to train in Medium Weapons" unless self.has_ability? "Weapons: Medium"
				end

				errors << "Does not satisfy requirements for '#{item.name}'" unless self.pass_requirements? item.requirements

				if self.primary_equiped? and self.primary.two_handed? and self.off_hand_equiped? and not self.has_ability? 'Weapons: Large'
					errors << 'Hands overfulll'
				end
			end

			return errors
		end
	end

	def warning_messages
		if self.race.nil?
			[]
		else
			warnings = []

			warnings << "Unspent Free Ability" if self.synergy_bonus
			warnings << "Unspent Ability points" if self.synergies['No Class'][:remaining] >= 2
			warnings << "Only Urgan Elite may use 'Were-Bear'" if self.has_ability? 'Were-Bear'

			unless self.race.eql? 'Wolf'
				warnings << "No Equiped Weapon" unless self.primary_equiped?
				if !self.off_hand_equiped? and (!self.primary_equiped? or self.primary.one_handed? or self.has_ability? 'Weapons: Large')
					warnings << "Nothing Equiped Off Hand"
				end
			end

			if self.has_ability? 'Atheist'
				self.skills.each do |skill|
					warnings << "An atheist cannot use '#{skill.name}'" unless skill.spell.nil?
				end
			end

			warnings << "Vampires must be atheists" if self.race == 'Vampire' and not self.has_ability? 'Atheist'
			warnings << "Vampires must be literate" if self.race == 'Vampire' and not self.has_ability? 'Literate'

			return warnings
		end
	end

end
