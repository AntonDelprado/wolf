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

class Character < ActiveRecord::Base
	attr_accessible :dex, :fai, :int, :name, :player, :race, :str
	serialize :skills
	serialize :abilities
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
		if self.skills.nil? && self.race
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
		end

		# always initialise synergies if there are skills
		if self.skills

			synergies = {}
			bonus_remaining = true
			ApplicationHelper::Synergy.names.each { |name| synergies[name] = [0,0] }

			self.skills.each do |skill_name, level|
				skill = ApplicationHelper::Skill.find_by_name(skill_name)
				synergies[skill.synergy.name][0] += level if skill.synergy
				synergies['Lore'][0] += level if skill.spell
			end

			synergies.each { |synergy, level_zero| synergies[synergy] = [level_zero[0]/10,0] } if self.race != 'Goblin'
			synergies.each { |synergy, level_zero| synergies[synergy] = [level_zero[0]/6,0] } if self.race == 'Goblin'

			self.abilities.each do |ability_name, level|
				ability = ApplicationHelper::Ability.find_by_name(ability_name)
				if ability.synergy
					if synergies[ability.synergy.name][0] < synergies[ability.synergy.name][1]+2
						if bonus_remaining
							bonus_remaining = false
						else
							synergies['No Class'][1] += 3
						end
					else
						synergies[ability.synergy.name][1] += 2
					end
				else
					synergies['No Class'][1] += 2
				end
			end

			spent = 0
			synergies.each { |synergy, level| spent += level[0] - level[1] unless synergy == 'No Class' }
			synergies['No Class'][0] = spent - synergies['No Class'][1]

			if synergies['No Class'][0] < 0 and bonus_remaining
				bonus_remaining = false
				synergies['No Class'][0] += 2
			end

			@synergy_bonus = bonus_remaining
			@synergies = synergies.reject { |synergy, level_spent| not synergy == 'No Class' and level_spent[0].zero? and level_spent[1].zero? }
		end
	end

	def export(file_type = :xml)
		case file_type
		when :xml
			doc = XML::Document.new()
			doc.root = XML::Node.new('Character')

			# Character, player and race
			doc.root << (XML::Node.new('Name') << XML::Node.new_text(self.name))
			doc.root << (XML::Node.new('Player') << XML::Node.new_text(self.player))
			doc.root << (XML::Node.new('Race') << XML::Node.new_text(self.race))

			# Stats
			doc.root << (XML::Node.new('Strength') << XML::Node.new_text(self.str.to_s))
			doc.root << (XML::Node.new('Dexterity') << XML::Node.new_text(self.dex.to_s))
			doc.root << (XML::Node.new('Intelligence') << XML::Node.new_text(self.int.to_s))
			doc.root << (XML::Node.new('Faith') << XML::Node.new_text(self.fai.to_s))

			# Skills
			self.skills.each do |skill_name, level|
				skill_node = XML::Node.new('Skill')
				skill_node.attributes['level'] = level.to_s
				skill_node << XML::Node.new_text(skill_name)
				doc.root << skill_node
			end

			# Abilities
			self.abilities.each do |ability_name|
				doc.root << (XML::Node.new('Ability') << XML::Node.new_text(ability_name))
			end

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
		added_skills = []

		if self.skills[skill_name].nil? || self.skills[skill_name] < level
			added_skills << skill_name if self.skills[skill_name].nil?
			self.skills[skill_name] = level
		end

		required_skill = ApplicationHelper::Skill.find_by_name(skill_name).requires
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

	def synergies
		@synergies
	end

	def synergy_bonus
		@synergy_bonus
	end

	def parse_effect_xml(skill, effect_xml)
		return effect_xml.content if effect_xml.find_first('skill').nil?

		total = effect_xml.attributes['add'].to_i
		effect_xml.find('skill').each { |skill_xml| total += self.skills[skill_xml.content].to_i }
		total += @synergies[skill.synergy.name][0] if skill.synergy && @synergies[skill.synergy.name]

		if skill.spell and self.abilities.any? { |ability_name| ability_name[0,8] == "Follower" }
			god = self.abilities.detect { |ability_name| ability_name[0,8] == "Follower" }.sub("Follower of ", "")
			if god == "Travaer"
				total += (skill.invertible?) ? 1 : -1
			else
				total += (skill.spell == god) ? 2 : -1
			end
		end
		# total += weapon bonus
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

	def hp
		hp_base = self.str + self.dex
		if self.synergies['Warrior']
			hp_base += (self.skills['Extra HP'].to_i + self.synergies['Warrior'][0]) * 3
			regen = ((self.skills['Regenerate'].to_f+self.synergies['Warrior'][0])/2).floor - 5
		else
			hp_base += self.skills['Extra HP'].to_i * 3
			regen = (self.skills['Regenerate'].to_f/2).floor - 5
		end

		case
		when regen == 0 then text = "#{hp_base} + 1/ Turn"
		when regen < 0 then text = "#{hp_base} + 1/ #{2**(-regen)} Turns"
		when regen > 0 then text = "#{hp_base} + #{1+regen} / Turn"
		end

		return "<span onClick=\"total_time(#{hp_base},#{regen})\">#{text}</span>".html_safe
	end

	def mp
		mp_base = self.int + self.fai
		if self.synergies['Trickster']
			mp_base += (self.skills['Extra MP'].to_i + self.synergies['Trickster'][0]) * 3
		else
			mp_base += self.skills['Extra MP'].to_i * 3
		end
		if self.synergies['Battle Mage']
			refresh = ((self.skills['Refresh'].to_f+self.synergies['Battle Mage'][0])/2).floor - 5
		else
			refresh = (self.skills['Refresh'].to_f/2).floor - 5
		end

		case
		when refresh == 0 then text = "#{mp_base} + 1/ Turn"
		when refresh < 0 then text = "#{mp_base} + 1/ #{2**(-refresh)} Turns"
		when refresh > 0 then text = "#{mp_base} + #{1+refresh} / Turn"
		end

		return "<span onClick=\"total_time(#{mp_base},#{refresh})\">#{text}</span>".html_safe
	end

	def remove_confirmation(skill)
		required = skill.all_required.collect{ |skill| skill.name if self.skills.has_key? skill.name }.compact
		return "Removing '#{skill.name}' will also remove: #{required.join(', ')}. Proceed?" unless required.empty?
	end

	def error_messages
		errors = []

		if @synergies
			# spent = 0
			# @synergies.each { |synergy, level_spent| spent += level_spent[1] - level_spent[0]}
			errors << "Overspent Abilities by #{-@synergies['No Class'][0]} Points." if @synergies['No Class'][0] < 0
			# errors << @synergies.inspect
		end

		if self.skills
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

		return errors
	end

	def warning_messages
		warnings = []

		warnings << "Unspent Free Ability" if @synergy_bonus
		warnings << "Unspent Ability points" if @synergies and @synergies['No Class'][0] >= 2
		warnings << "Only Urgan Elite may use 'Were-Bear'" if self.abilities and self.abilities.include? 'Were-Bear'

		return warnings
	end

end
