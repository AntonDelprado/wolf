# == Schema Information
#
# Table name: characters
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  player     :string(255)
#  str        :integer
#  dex        :integer
#  int        :integer
#  fai        :integer
#  skills     :text
#  abilities  :text
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

include ApplicationHelper

class Character < ActiveRecord::Base
	attr_accessible :dex, :fai, :int, :name, :player, :race, :str
	serialize :skills
	serialize :abilities
	serialize :items
	after_initialize :init_rest

	validates :name, presence: true, length: { maximum: 100 }
	validates :player, presence: true, length: { maximum: 100 }
	validates :race, presence: true, inclusion: %w[Wolf Dwarf Goblin Vampire]
	validates :str, presence: true, inclusion: [4,6,8,10,12]
	validates :dex, presence: true, inclusion: [4,6,8,10,12]
	validates :int, presence: true, inclusion: [4,6,8,10,12]
	validates :fai, presence: true, inclusion: [4,6,8,10,12]

	def self.stats(race="Wolf")
		case race
		when "Wolf", "Dwarf" then return [[12,4,4,4], [10,10,4,4], [10,8,6,4], [8,8,8,6]]
		when "Vampire" then return [[12,12,12,4]]
		when "Goblin" then return [[8,6,4,4], [6,6,6,6]]
		else [[0,0,0,0]]
		end
	end

	def self.join_stats(stats)
		return "#{stats[0]} Str, #{stats[1]} Dex, #{stats[2]} Int, #{stats[3]} Fai"
	end

	def init_rest
		# initialze only on create, not on new/find
		if self.skills.nil? and self.race
			stats_new = self.class.stats(self.race)[0]
			self.str = stats_new[0]
			self.dex = stats_new[1]
			self.int = stats_new[2]
			self.fai = stats_new[3]

			self.skills = {
				'Endurance' => self.str/2,
				'Sprint' => self.dex/2,
				'Observation' => self.int/2,
				'Sense' => self.fai/2
			}
			self.abilities = []
			self.abilities << 'Atheist' << 'Literate' if self.race == 'Vampire'
			self.items = {}
		end

		# always initialise synergies if there are skills
		if self.skills
			self.items ||= {}

			synergies = {}
			bonus_remaining = true
			ApplicationHelper::Synergy.names.each { |name| synergies[name] = { level: 0, spent: 0 } }


			self.skills.each do |skill_name, level|
				skill = ApplicationHelper::Skill.find_by_name skill_name
				synergies[skill.synergy.name][:level] += level if skill.synergy
				synergies['Lore'][:level] += level if skill.spell
			end

			if race == 'Goblin'
				synergies.each { |synergy_name, synergy| synergy[:level] /= 6 }
			else
				synergies.each { |synergy_name, synergy| synergy[:level] /= 10 }
			end

			self.abilities.each do |ability_name, level|
				ability = ApplicationHelper::Ability.find_by_name(ability_name)
				if ability.synergy
					if synergies[ability.synergy.name][:level] < synergies[ability.synergy.name][:spent]+2
						bonus_remaining ? bonus_remaining = false : synergies['No Class'][:spent] += 3
					else
						synergies[ability.synergy.name][:spent] += 2
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
	end

	def self.import_xml(xml_root)
		begin
			character = Character.new

			character.name = xml_root.find_first('Name').content
			character.player = xml_root.find_first('Player').content
			character.race = xml_root.find_first('Race').content

			stats_xml = xml_root.find_first('Stats')
			character.str = stats_xml.find_first('Strength').content.to_i
			character.dex = stats_xml.find_first('Dexterity').content.to_i
			character.int = stats_xml.find_first('Intelligence').content.to_i
			character.fai = stats_xml.find_first('Faith').content.to_i

			character.skills = {}
			xml_root.find_first('Skills').find('Skill').each do |skill_node|
				character.add_skill(skill_node.content, skill_node.attributes['level'].to_i)
			end

			character.add_skill('Endurance', character.str/2)
			character.add_skill('Sprint', character.dex/2)
			character.add_skill('Observation', character.int/2)
			character.add_skill('Sense', character.fai/2)

			character.abilities = []
			xml_root.find_first('Abilities').find('Ability').each do |ability_node|
				character.add_ability ability_node.content
			end

			items_xml = xml_root.find_first('Items')
			character.equip_with_name(:primary, items_xml.find_first('Primary').content) if items_xml.find_first('Primary')
			character.equip_with_name(:off_hand, items_xml.find_first('OffHand').content) if items_xml.find_first('OffHand')
			character.equip_with_name(:armour, items_xml.find_first('Armour').content) if items_xml.find_first('Armour')

			return character
		rescue NoMethodError
			return nil
		end
	end

	def export_xml(file_type = :xml)
		case file_type
		when :xml
			doc = XML::Document.new()
			doc.root = XML::Node.new('Character')

			# Character, player and race
			doc.root << (XML::Node.new('Name') << XML::Node.new_text(self.name))
			doc.root << (XML::Node.new('Player') << XML::Node.new_text(self.player))
			doc.root << (XML::Node.new('Race') << XML::Node.new_text(self.race))

			# Stats
			stats_node = XML::Node.new('Stats')
			stats_node << (XML::Node.new('Strength') << XML::Node.new_text(self.str.to_s))
			stats_node << (XML::Node.new('Dexterity') << XML::Node.new_text(self.dex.to_s))
			stats_node << (XML::Node.new('Intelligence') << XML::Node.new_text(self.int.to_s))
			stats_node << (XML::Node.new('Faith') << XML::Node.new_text(self.fai.to_s))

			# Skills
			skills_node = XML::Node.new('Skills')
			self.skills.each do |skill_name, level|
				skill_node = XML::Node.new('Skill')
				skill_node.attributes['level'] = level.to_s
				skill_node << XML::Node.new_text(skill_name)
				skills_node << skill_node
			end

			# Abilities
			abilities_node = XML::Node.new('Abilities')
			self.abilities.each do |ability_name|
				abilities_node << (XML::Node.new('Ability') << XML::Node.new_text(ability_name))
			end

			# Items
			items_node = XML::Node.new('Items')
			items_node << (XML::Node.new('Primary') << XML::Node.new_text(items[:primary][:name])) if items[:primary]
			items_node << (XML::Node.new('OffHand') << XML::Node.new_text(items[:off_hand][:name])) if items[:off_hand]
			items_node << (XML::Node.new('Armour') << XML::Node.new_text(items[:armour][:name])) if items[:armour]

			doc.root << stats_node << skills_node << abilities_node << items_node

			return doc
		end
	end

	def update_base_skills
		self.skills['Endurance'] = [self.skills['Endurance'], self.str/2].max
		self.skills['Sprint'] = [self.skills['Sprint'], self.dex/2].max
		self.skills['Observation'] = [self.skills['Observation'], self.int/2].max
		self.skills['Sense'] = [self.skills['Sense'], self.fai/2].max
	end

	def add_skill(skill_name, level=1)
		skill = ApplicationHelper::Skill.find_by_name(skill_name)
		return nil if skill.nil?

		added_skills = []
		if self.skills[skill_name].nil? || self.skills[skill_name] < level
			added_skills << skill_name if self.skills[skill_name].nil?
			self.skills[skill_name] = level
		end

		required_skill = skill.requires
		added_skills.concat self.add_skill(required_skill.name, level+1) if required_skill and required_skill.class == ApplicationHelper::Skill

		return added_skills
	end

	def set_skill_level(skill_name, level)
	end

	def min_skill_level(skill_name)
		return 0 unless self.skills.has_key? skill_name

		base_levels = [1]
		base_levels << str/2 if skill_name == 'Endurance'
		base_levels << dex/2 if skill_name == 'Sprint'
		base_levels << int/2 if skill_name == 'Observation'
		base_levels << fai/2 if skill_name == 'Sense'

		ApplicationHelper::Skill.find_by_name(skill_name).required_by.each do |required_skill|
			base_levels << 1 + self.min_skill_level(required_skill.name)
		end

		return base_levels.max
	end

	def remove_skill(skill_name)
		return nil if ApplicationHelper::Skill.base_skills.include? skill_name # sanity check
		skill = ApplicationHelper::Skill.find_by_name(skill_name)
		self.skills.delete skill_name
		removed_skills = [skill_name]
		skill.all_required.each do |required_skill|
			if self.skills.has_key? required_skill.name
				self.skills.delete required_skill.name
				removed_skills << required_skill.name
			end
		end
		return removed_skills.join(', ')
	end

	def add_ability(ability_name)
		return nil unless ApplicationHelper::Ability.find_by_name(ability_name)
		self.abilities << ability_name
	end

	def remove_ability(ability_name)
		self.abilities.delete ability_name
	end

	def can_add_skills
		skills = ApplicationHelper::Skill.all.reject { |skill| self.skills.has_key? skill.name }
		skills.reject! { |skill| (skill.name.include? "Will of") && !self.abilities.include?(skill.name.sub("Will of", "Follower of")) }
		return skills
	end

	def can_add_abilities
		abilities = ApplicationHelper::Ability.all.reject { |ability| self.abilities.include? ability.name }
		abilities.reject! { |ability| (ability.name.include? "Follower of") && !self.follower_of.nil? }
		return abilities
	end

	def equip(equipment)
		self.items ||= {}
		equiped = []

		if equipment[:primary] == 'None'
			self.items.delete :primary
		else
			self.items[:primary] = weapons.detect { |weapon| weapon[:name].eql? equipment[:primary] }
			equiped << self.items[:primary]
		end

		if equipment[:off_hand] == 'None'
			self.items.delete :off_hand
		else
			self.items[:off_hand] = weapons.concat(shields).detect { |item| item[:name].eql? equipment[:off_hand] }
			equiped << self.items[:off_hand]
		end

		if equipment[:armour] == 'Cloth'
			self.items.delete :armour
		else
			self.items[:armour] = armours.detect { |armour| armour[:name].eql? equipment[:armour] }
			equiped << self.items[:armour]
		end

		return equiped
	end

	def equip_with_name(slot, item_name)
		self.items ||= {}
		item = weapons.concat(shields).concat(armours).detect { |item| item[:name] == item_name }
		self.items[slot] = item unless item.nil?
	end

	def pass_require?(requirements)
		return true if requirements.nil?
		requirements.all? do |type, value|
			case type
			when :str then self.str >= value
			when :dex then self.dex >= value
			when :int then self.int >= value
			when :fai then self.fai >= value
			when :xp then self.xp >= value
			when :spell_xp then self.xp :spell >= value
			when :abilities then value.all? { |ability| self.abilities.include? ability }
			end
		end
	end

	def can_equip(slot)
		case slot
		when :primary
			return weapons.select { |weapon| self.pass_require? weapon[:require] }.collect { |weapon| weapon[:name] }.unshift('None')
		when :off_hand
			if self.abilities.include? "Ambidextrous"
				off_hand_equip = weapons.select { |weapon| self.pass_require? weapon[:require] } if self.abilities.include? "Weapons: Large"
				off_hand_equip ||= weapons.select { |weapon| self.pass_require? weapon[:require] and weapon[:hands] == 1 }
			end
			off_hand_equip ||= []
			shields.each { |shield| off_hand_equip << shield if self.pass_require? shield[:require] }
			return off_hand_equip.collect { |item| item[:name] }.unshift('None')
		when :armour
			return armours.select { |armour| self.pass_require? armour[:require] }.collect { |armour| armour[:name] }
		end
	end

	def primary
		self.items[:primary]
	end

	def off_hand
		self.items[:off_hand]
	end

	def armour
		self.items[:armour]
	end

	# index1 represents which ba
	def base_stats(index_base = nil, index_raw = nil)
		return self.class.stats(self.race) if index_base.nil?
		if self.class == 'Vampire'
			return [[12,12,12,4]] if index_raw.nil?
			return [12,12,12,4]
		else
			return self.class.stats(self.race)[index_base].permutation.to_a.uniq if index_raw.nil?
			return self.class.stats(self.race)[index_base].permutation.to_a.uniq[index_raw]
		end
	end

	def follower_of
		self.abilities.each { |ability| return ability if ability.include? "Follower of" }
		return nil
	end

	def stats
		[self.str, self.dex, self.int, self.fai]
	end

	def str_mod
		mod = 0
		self.items.each { |slot, item| mod += item[:effect][:str].to_i unless item[:effect].nil? }
		return mod
	end

	def dex_mod
		mod = 0
		self.items.each { |slot, item| mod += item[:effect][:dex].to_i unless item[:effect].nil? }
		return mod
	end

	def int_mod
		mod = 0
		self.items.each { |slot, item| mod += item[:effect][:int].to_i unless item[:effect].nil? }
		return mod
	end

	def fai_mod
		mod = 0
		self.items.each { |slot, item| mod += item[:effect][:fai].to_i unless item[:effect].nil? }
		return mod
	end

	def str_mod_s
		return "+0" if self.str_mod.nil?
		return "+#{self.str_mod}" if self.str_mod >= 0
		return "#{self.str_mod}"
	end

	def dex_mod_s
		return "+0" if self.dex_mod.nil?
		return "+#{self.dex_mod}" if self.dex_mod >= 0
		return "#{self.dex_mod}"
	end

	def int_mod_s
		return "+0" if self.int_mod.nil?
		return "+#{self.int_mod}" if self.int_mod >= 0
		return "#{self.int_mod}"
	end

	def fai_mod_s
		return "+0" if self.fai_mod.nil?
		return "+#{self.fai_mod}" if self.fai_mod >= 0
		return "#{self.fai_mod}"
	end

	def str_final
		return self.str + 2*self.str_mod if self.str_mod
		return self.str
	end

	def dex_final
		return self.dex + 2*self.dex_mod if self.dex_mod
		return self.dex
	end

	def int_final
		return self.int + 2*self.int_mod if self.int_mod
		return self.int
	end

	def fai_final
		return self.fai + 2*self.fai_mod if self.fai_mod
		return self.fai
	end

	def primary
		self.items[:primary]
	end

	def off_hand
		self.items[:off_hand]
	end

	def armour
		self.items[:armour]
	end

	def synergies
		@synergies
	end

	def synergy_bonus
		@synergy_bonus
	end

	def parse_effect_xml(skill, effect_xml)
		return effect_xml.content if effect_xml.find_first('skill').nil?

		total = effect_xml.attributes['add'].to_i
		effect_xml.find('skill').each { |skill_xml| total += self.skills[Skill.find_by_name(skill_xml.content).name].to_i }
		total += @synergies[skill.synergy.name][:level] if skill.synergy && @synergies[skill.synergy.name]

		if skill.spell and self.abilities.any? { |ability_name| ability_name[0,8] == "Follower" }
			god = self.abilities.detect { |ability_name| ability_name[0,8] == "Follower" }.sub("Follower of ", "")
			if god == "Travaer"
				total += (skill.invertible?) ? 1 : -1
			else
				total += (skill.spell == god) ? 2 : -1
			end
		end
		total += self.weapon_bonus if effect_xml.attributes['weapon']
		self.items.each { |slot, item| total += item[:effect][skill.name].to_i if item[:effect] }
		total *= effect_xml.attributes['times'].to_f if effect_xml.attributes['times']
		total = total.floor

		return total.to_i.to_s unless effect_xml.attributes['type'] == 'roll'

		case skill.stat
		when 'Str' then dice_type = self.str_final
		when 'Dex' then dice_type = self.dex_final
		when 'Int' then dice_type = self.int_final
		when 'Fai' then dice_type = self.fai_final
		else dice_type = 0
		end

		return "<span onClick='roll(#{total.to_i}, #{dice_type})'>#{total.to_i}d#{dice_type}</span>".html_safe
	end

	def power(skill, effect)
		parse_effect_xml(skill, effect.power) if effect.power
	end

	def duration(skill, effect)
		parse_effect_xml(skill, effect.duration) if effect.duration
	end

	def stats_options(index = nil)
		return self.base_stats.each_with_index.collect { |stat, index| [stat.join(", "), index]} if index.nil?
		return [["12, 12, 12, 4", 0]] if self.race == "Vampire"
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
		skills.each do |skill_name, level|
			if type == :spell
				skill = ApplicationHelper::Skill.find_by_name(skill_name)
				spent_xp += skill.cost.to_i * level if skill.spell
			elsif type.nil?
				spent_xp += ApplicationHelper::Skill.find_by_name(skill_name).cost.to_i * level
			end
		end
		return spent_xp
	end

	def hp_max
		return self.str + self.dex + 3*(self.skills['Extra HP'].to_i + @synergies['Warrior'][:level]) if @synergies['Warrior']
		return self.str + self.dex + 3*self.skills['Extra HP'].to_i
	end

	def hp_rate
		return ((self.skills['Regenerate'].to_f+self.synergies['Warrior'][:level])/2).floor - 5 if @synergies['Warrior']
		return ((self.skills['Regenerate'].to_f)/2).floor - 5
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
		return self.int + self.fai + 3*(self.skills['Extra MP'].to_i + @synergies['Lore'][:level]) if @synergies['Lore']
		return self.int + self.fai + 3*self.skills['Extra MP'].to_i
	end

	def mp_rate
		return ((self.skills['Refresh'].to_f+@synergies['Lore'][:level])/2).floor - 5 if @synergies['Lore']
		return ((self.skills['Refresh'].to_f)/2).floor - 5
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

	def remove_confirmation(skill)
		required = skill.all_required.collect{ |skill| skill.name if self.skills.has_key? skill.name }.compact
		return "Removing '#{skill.name}' will also remove: #{required.join(', ')}. Proceed?" unless required.empty?
	end

	def damage_reduction
		dr = 0
		self.items.each do |slot, item|
			dr += item[:effect][:dr].to_i if item[:effect]
		end
		return dr
	end

	def weapon_bonus
		bonus = 0
		self.items.each { |slot, item| bonus += item[:bonus].to_i }
		return bonus
	end

	def error_messages
		errors = []

		if @synergies
			errors << "Overspent Abilities by #{-@synergies['No Class'][:remaining]} Points." if @synergies['No Class'][:remaining] < 0
		end

		if self.skills
			errors << "Invalid Stats" unless Character.stats(self.race).include? self.stats.sort.reverse

			errors << "May Only Follow One God" if self.abilities.select{ |ability| ability.include? "Follower" }.count > 1

			self.skills.each do |skill_name, level|
				if skill_name.include? "Will of" and !(abilities.include? skill_name.sub("Will of", "Follower of"))
					god = skill_name.sub("Will of ", "")
					errors << "Need to be a follower of #{god} to use '#{skill_name}'"
				end
			end

			errors << "Only Wolves and Vampires may use 'Devour'" if self.skills.has_key? 'Devour' and not %[Wolf Vampire].include? self.race

			self.abilities.each do |ability_name|
				ability = ApplicationHelper::Ability.find_by_name(ability_name)
				if ability.require_xml
					(ability.require_xml.find('XP') || []).each do |xp_xml|
						if xp_xml.attributes['type'] == 'Spell' and (self.xp :spell) < xp_xml.content.to_i
							errors << "Need #{xp_xml.content.to_i} XP Spent in Spells. Only Have #{self.xp :spell}"
						end
						if xp_xml.attributes['type'].nil? and self.xp < xp_xml.content.to_i
							errors << "Need #{xp_xml.content.to_i} XP Spent. Only Have #{self.xp}"
						end
					end
					(ability.require_xml.find('Race') || []).each do |race_xml|
						errors << "'#{ability_name}' requires race '#{race_xml.content}'" if race_xml.content != self.race
					end
					(ability.require_xml.find('Ability') || []).each do |ability_xml|
						errors << "'#{ability_name}' requires '#{ability_xml.content}'" unless self.abilities.include? ability_xml.content
					end
				end
			end
		end

		if self.items
			self.items.each do |slot, item|
				if item[:type]
					case item[:type]
					when :ranged then errors << "Need to train in Ranged Weapons" unless self.abilities.include? "Weapons: Ranged"
					when :medium, :large then errors << "Need to train in Medium Weapons" unless self.abilities.include? "Weapons: Medium"
					end
				end

				errors << "Does not satisfy requirements for '#{item[:name]}'" unless self.pass_require? item[:require]
			end

			if self.primary and self.primary[:hands] == 2 and self.off_hand and not self.abilities.include? "Weapons: Large"
				errors << "Hands overfull"
			end			
		end

		return errors
	end

	def warning_messages
		warnings = []

		warnings << "Unspent Free Ability" if @synergy_bonus
		warnings << "Unspent Ability points" if @synergies and @synergies['No Class'][:remaining] >= 2
		warnings << "Only Urgan Elite may use 'Were-Bear'" if self.abilities and self.abilities.include? 'Were-Bear'

		unless self.race.eql? 'Wolf' or self.items.nil?
			warnings << "No Equiped Weapon" if self.items[:primary].nil?
			if self.items[:off_hand].nil? and (self.items[:primary].nil? or self.items[:primary][:hands] == 1 or self.abilities.include? "Weapons: Large")
				warnings << "Nothing Equiped Off Hand"
			end
		end

		if self.abilities and self.abilities.include? "Atheist"
			self.skills.each do |skill_name, level|
				skill = Skill.find_by_name skill_name
				warnings << "As an atheist, cannot use '#{skill_name}'" if skill.spell
			end
		end

		warnings << "Vampires must be atheists" if self.race == 'Vampire' and not self.abilities.include? 'Atheist'
		warnings << "Vampires must be literate" if self.race == 'Vampire' and not self.abilities.include? 'Literate'

		return warnings
	end

end
