require 'xml'

# module ObjectExtension
#   def nil_or
#     return self unless self.nil?
#     Class.new do
#       def method_missing(sym, *args); nil; end
#     end.new
#   end
# end
 
# class Object
#   include ObjectExtension
# end

module ApplicationHelper

	def full_title(page_title = nil)
		base_title = "Wolf RPG"
		return "#{base_title} | #{page_title}" if page_title
	end

	def str
		'<span class="label label-success">Strength</span>'.html_safe
	end

	def dex
		'<span class="label label-success">Dexterity</span>'.html_safe
	end

	def int
		'<span class="label label-success">Intelligence</span>'.html_safe
	end

	def fai
		'<span class="label label-success">Faith</span>'.html_safe
	end

	def major_action
		'<span class="label label-inverse">Major Action</span>'.html_safe
	end

	def minor_action
		'<span class="label label-inverse">Minor Action</span>'.html_safe
	end

	def move_action
		'<span class="label label-inverse">Move Action</span>'.html_safe
	end

	def hp(amount = nil)
		return '<span class="label label-important">HP</span>'.html_safe if amount == nil
		return '<span class="label label-important">HP Max</span>'.html_safe if amount == "max"
		return "<span class=\"label label-important\">#{amount} HP</span>".html_safe
	end

	def mp(amount = nil)
		return '<span class="label label-info">MP</span>'.html_safe if amount == nil
		return '<span class="label label-info">MP Max</span>'.html_safe if amount == "max"
		return "<span class=\"label label-info\">#{amount} MP</span>".html_safe
	end

	def skill(skill_name)
		return "<span class=\"label\">#{skill_name}</span>".html_safe if skill_name.class == String
		return "<span class=\"label\">#{skill_name.name}</span>".html_safe
	end

	def rate(value)
		case
		when value == 0 then text = "1/ Turn"
		when value < 0 then text = "1/ #{2**(-value)} Turns"
		when value > 0 then text = "#{1+value} / Turn"
		end
	end

	def check(skill_name, stat_name)
		# case stat_name.downcase
		# when 'str' then stat_name = "Strength"
		# when 'dex' then stat_name = "Dexterity"
		# when 'int' then stat_name = "Intelligence"
		# when 'fai' then stat_name = "Faith"
		# end
		"<span class=\"label label-warning\">#{skill_name.capitalize}:#{stat_name.capitalize}</span>".html_safe
	end

	def parse_require(require_xml)
		requirements = {}
		require_xml.children.each do |require_node|
			case require_node.name
			when 'Str' then requirements[:str] = require_node.content.to_i
			when 'Dex' then requirements[:dex] = require_node.content.to_i
			when 'Int' then requirements[:int] = require_node.content.to_i
			when 'Fai' then requirements[:fai] = require_node.content.to_i
			when 'Race' then requirements[:race] = require_node.content
			when 'Ability'
				requirements[:abilities] ||= []
				requirements[:abilities] << require_node.content
			when 'XP'
				if require_node.attributes['type'] == 'Spell'
					requirements[:spell_xp] = require_node.content.to_i
				else
					requirements[:xp] = require_node.content.to_i
				end
			else requirements[:custom] = require_node.content
			end
		end
		requirements
	end

	def parse_effect(effect_xml)
		effects = {}
		effect_xml.children.each do |effect_node|
			case effect_node.name
			when 'DR' then effects[:dr] = effect_node.content.to_i
			when 'Str' then effects[:str] = effect_node.content.to_i
			when 'Dex' then effects[:dex] = effect_node.content.to_i
			when 'Int' then effects[:int] = effect_node.content.to_i
			when 'Fai' then effects[:fai] = effect_node.content.to_i
			when 'skill'
				effects[effect_node.content] = effect_node.attributes['add'].to_i 
			end
		end
		effects
	end

	def armours
		unless @armours
			@armours = []
			XML::Parser.file('app/data/skills.xml').parse.root.find('Armour').each do |armour_xml|
				armour = { name: armour_xml.find_first('Name').content }
				armour[:require] = parse_require armour_xml.find_first('Require') if armour_xml.find_first('Require')
				armour[:effect] = parse_effect armour_xml.find_first('Effect') if armour_xml.find_first('Effect')
				armour[:quick] = armour_xml.find_first('Quick').content if armour_xml.find_first('Quick')
				armour[:quick] ||= ""

				@armours << armour
			end
		end

		@armours
	end

	def weapons
		unless @weapons
			@weapons = []
			XML::Parser.file('app/data/skills.xml').parse.root.find('Weapon').each do |weapon_xml|
				weapon = {
					name:   weapon_xml.find_first('Name').content,
					hands:  weapon_xml.find_first('Hands').content.to_i,
					type:   weapon_xml.find_first('Class').content.downcase.to_sym,
					damage: weapon_xml.find_first('Damage').content.downcase.to_sym,
					bonus:  weapon_xml.find_first('Bonus').content.to_i,
				}
				weapon[:range] = weapon_xml.find_first('Range').content if weapon_xml.find_first('Range')

				weapon[:require] = parse_require weapon_xml.find_first('Require') if weapon_xml.find_first('Require')
				weapon[:effect] = parse_effect weapon_xml.find_first('Effect') if weapon_xml.find_first('Effect')
				weapon[:quick] = weapon_xml.find_first('Quick').content if weapon_xml.find_first('Quick')
				weapon[:quick] ||= ""
				
				@weapons << weapon
			end
		end

		@weapons
	end

	def shields
		unless @shields
			@shields = []
			XML::Parser.file('app/data/skills.xml').parse.root.find('Shield').each do |shield_xml|
				shield = { name: shield_xml.find_first('Name').content }
				shield[:require] = parse_require shield_xml.find_first('Require') if shield_xml.find_first('Require')
				shield[:effect] = parse_effect shield_xml.find_first('Effect') if shield_xml.find_first('Effect')
				shield[:quick] = shield_xml.find_first('Quick').content if shield_xml.find_first('Quick')
				shield[:quick] ||= ""

				@shields << shield
			end
		end
		
		@shields
	end

	class Synergy
		def self.names
			['Warrior', 'Rogue', 'Channeller', 'Mechanist', 'Trickster', 'Battle Mage', 'Necromancer', 'Lore', 'No Class']
		end

		def self.css_class(name)
			return 'name-warrior' if name == 'Warrior'
			return 'name-rogue' if name == 'Rogue'
			return 'name-channeller' if name == 'Channeller'
			return 'name-mechanist' if name == 'Mechanist'
			return 'name-trickster' if name == 'Trickster'
			return 'name-battle-mage' if name == 'Battle Mage'
			return 'name-necromancer' if name == 'Necromancer'
			return 'name-lore' if name == 'Lore'
			return 'name-no-synergy'
		end

		def initialize(name = nil)
			@class = case name
			when 'Warrior' then :warrior
			when 'Rogue' then :rogue
			when 'Channeller' then :channeller
			when 'Mechanist' then :mechanist
			when 'Trickster' then :trickster
			when 'Battle Mage' then :battle_mage
			when 'Necromancer' then :necromancer
			when 'Lore' then :lore
			else :none
			end
		end

		def colour
			return '#fdd' if @class == :warrior
			return '#ddf' if @class == :rogue
			return '#ffd' if @class == :channeller
			return '#eee' if @class == :mechanist
			return '#fff1d8' if @class == :trickster
			return '#fdf' if @class == :battle_mage
			return '#dfd' if @class == :necromancer
			return '#cdc' if @class == :lore
			return '#ddd'
		end

		def name
			return 'Warrior' if @class == :warrior
			return 'Rogue' if @class == :rogue
			return 'Channeller' if @class == :channeller
			return 'Mechanist' if @class == :mechanist
			return 'Trickster' if @class == :trickster
			return 'Battle Mage' if @class == :battle_mage
			return 'Necromancer' if @class == :necromancer
			return 'Lore' if @class == :lore
			return 'None'
		end

		def css_class
			return 'warrior' if @class == :warrior
			return 'rogue' if @class == :rogue
			return 'channeller' if @class == :channeller
			return 'mechanist' if @class == :mechanist
			return 'trickster' if @class == :trickster
			return 'battle-mage' if @class == :battle_mage
			return 'necromancer' if @class == :necromancer
			return 'lore' if @class == :lore
			return 'no-synergy'
		end
	end

	class Effect
		attr_accessor :quick, :mana, :power, :duration
		def initialize(xml_node)
			@quick_raw = xml_node.find_first('Quick')
			@mana = xml_node.find_first('Mana').content if xml_node.find_first('Mana')
			@power = xml_node.find_first('Power')
			@duration = xml_node.find_first('Duration')

			if xml_node.find_first('Action')
				case xml_node.find_first('Action').content.downcase
				when 'major' then @action = :major_action
				when 'minor' then @action = :minor_action
				when 'attack' then @action = :attack_action
				when 'defend' then @action = :defend_action
				end
			end
		end

		def action
			@action
		end

		def attack?
			@action == :attack_action
		end

		def defend?
			@action == :defend_action
		end

		def quick
			return @quick_text if @quick_text
			case @action
			when :major_action then text = '<span class="label label-inverse">Major Action</span>&nbsp;'
			when :minor_action then text = '<span class="label label-inverse">Minor Action</span>&nbsp;'
			else text = ""
			end
			text << Skill.parse_text(@quick_raw).gsub(/<\/?p>/, '') # regexp removes paragraph tags
			@quick_text = text.html_safe
		end
	end

	class Skill
		attr_accessor :name, :name_inv, :stat, :cost, :full_text, :effects, :synergy, :spell, :requires, :required_by

		@@skills = nil
		@@statless = nil
		@@base_skills = ['Endurance', 'Sprint', 'Observation', 'Sense']

		def self.base_skills
			return @@base_skills
		end

		def self.all
			if @@skills == nil
				@@skills = []
				XML::Parser.file('app/data/skills.xml').parse.root.find('Skill').each do |skill|
					@@skills << Skill.new(skill)
				end

				@@statless = Skill.new(XML::Document.string('<Skill><Name>Statless</Name><Cost></Cost><Text></Text></Skill>'))

				# Base skills names
				endurance = Skill.find_by_name('Endurance')
				sprint = Skill.find_by_name('Sprint')
				observation = Skill.find_by_name('Observation')
				sense = Skill.find_by_name('Sense')

				# Stat based skills require some skill
				@@skills.each do |skill|
					if skill.requires == nil
						case skill.stat
						when 'Str' then skill.requires = endurance if skill != endurance
						when 'Dex' then skill.requires = sprint if skill != sprint
						when 'Int' then skill.requires = observation if skill != observation
						when 'Fai' then skill.requires = sense if skill != sense
						end
					else
						required_skill = Skill.find_by_name(skill.requires)
						skill.requires = required_skill if required_skill
					end

					skill.requires.required_by << skill if skill.requires && skill.requires.class == Skill
					@@statless.required_by << skill if skill.requires == nil && skill.stat == nil
				end
			end
			return @@skills
		end

		def self.statless
			return @@statless
		end

		def self.find_by_name(name)
			Skill.all.detect { |skill| skill.name == name || skill.name_inv == name}
		end

		def self.parse_text(xml_text)
			text = "<p>"
			xml_text.each do |node|
				case node.name.downcase
				when 'text' then text << node.content.gsub("\n", '</p><p>')
				when 'half' then text << "&frac12"
				when 'third' then text << "&#8531"
				when 'times' then text << "&times;"
				when 'name'
					if node.content == 'Minor Action'
						text << '<span class="label label-inverse">Minor Action</span>'
					elsif node.content == 'Major Action'
						text << '<span class="label label-inverse">Major Action</span>'
					elsif Skill.all.any? { |skill| skill.name == node.content } ||
						Ability.all.any? { |ability| ability.name == node.content }
						text << "<span class=\"label\">#{node.content}</span>"
					else
						# text << "<a href=\"\##{node.content}\">#{node.content}</a>"
						text << "<b>#{node.content}</b>"
					end
				when 'str' then text << "<span class=\"label label-success\">Strength</span>"
				when 'dex' then text << "<span class=\"label label-success\">Dexterity</span>"
				when 'int' then text << "<span class=\"label label-success\">Intelligence</span>"
				when 'fai' then text << "<span class=\"label label-success\">Faith</span>"
				when 'hp'
					if node.content && node.content == 'max'
						text << "<span class=\"label label-important\">HP Max</span>"
					elsif node.content
						text << "<span class=\"label label-important\">#{node.content} HP</span>"
					else
						text << "<span class=\"label label-important\">HP</span>"
					end
				when 'mp'
					if node.content && node.content == 'max'
						text << "<span class=\"label label-info\">MP Max</span>"
					elsif node.content
						text << "<span class=\"label label-info\">#{node.content} MP</span>"
					else
						text << "<span class=\"label label-info\">MP</span>"
					end
				when 'xp' then text << '<span class="label">XP</span>'
				when 'hpmax' then text << "<span class=\"label label-important\">HP Max</span>"
				when 'mpmax' then text << "<span class=\"label label-info\">MP Max</span>"
				when 'emph' then text << "<em>#{node.content}</em>"
				when 'check'
					stat = node.attributes['type'] ? node.attributes['type'].capitalize : ""
					skill = ""
					node.each do |inner_node|
						if inner_node.name == 'times'
							skill << '&times;'
						else
							skill << inner_node.content
						end
					end
					text << "<span class=\"label label-warning\">#{skill}:#{stat}</span>"

				else text << "<b>#{node.content} *** (#{node.name})</b>"
				end
			end

			return text + "</p>"
		end

		def initialize(xml_node)
			# Find the Name
			xml_node.find('Name').each do |name|
				if @name
					@name_inv = name.content
				else
					@name = name.content
				end
			end

			# Find the associated stat and cost.
			@stat = xml_node.find_first('Stat').content if xml_node.find_first('Stat')
			@cost = xml_node.find_first('Cost').content
			@requires = xml_node.find_first('Require').content if xml_node.find_first('Require')
			@required_by = [] # empty for now. will be filled as part of Skill.all

			# Find the effects
			@effects = []
			xml_node.find('Effect').each do |effect|
				@effects << Effect.new(effect)
			end

			# Find the synergy group
			@synergy = Synergy.new(xml_node.find_first('Synergy').content) if xml_node.find_first('Synergy')

			if xml_node.find_first('Spell')
				@spell = xml_node.find_first('Spell').content
				# @spell = case xml_node.find_first('Spell').content
				# when 'Arthur' then :arthur
				# when 'Innodi' then :innodi
				# when "Ird'ken" then :irdken
				# when 'Oxdoro' then :oxdoro
				# when 'Loreanna' then :loreanna
				# when 'Travaer' then :travaer
				# end
			end

			# Find if dividible or invertible
			@dividible = (xml_node.find_first('Divide') != nil)
			@invertible = (xml_node.find_first('Invert') != nil)

			# Find full text
			@raw_text = xml_node.find_first('Text')
			@full_text = nil
		end

		# Text parsing is lazy so as to let references be built first.
		def full_text
			return @full_text if @full_text
			@full_text = Skill.parse_text(@raw_text).html_safe
		end

		def full_name
			name = @name
			name = "#{@name} / #{@name_inv}" if @name_inv
			return "<h3 id=\"#{@name}\"> #{name} </h3>".html_safe
		end

		def synergy_css(added_str = "")
			synergy_name = @synergy ? @synergy.css_class : "no-synergy"
			return "#{added_str}#{synergy_name}"
		end

		def icons
			icon_list = []

			icon_list << '<img src="/assets/attack.png" alt="Attack" class="skill-icons"/>' if self.attack?
			icon_list << '<img src="/assets/defend.png" alt="Defend" class="skill-icons"/>' if self.defend?
			icon_list << '<img src="/assets/invertible.png" alt="Attack" class="skill-icons"/>' if self.invertible?
			icon_list << '<img src="/assets/dividible.png" alt="Defend" class="skill-icons"/>' if self.dividible?
			case @stat.downcase
			when 'str' then icon_list << '<img src="/assets/str.png" alt="Str" class="skill-icons"/>'
			when 'dex' then icon_list << '<img src="/assets/dex.png" alt="Dex" class="skill-icons"/>'
			when 'int' then icon_list << '<img src="/assets/int.png" alt="Int" class="skill-icons"/>'
			when 'fai' then icon_list << '<img src="/assets/fai.png" alt="Fai" class="skill-icons"/>'
			end if !@stat.nil?

			return icon_list.join.html_safe
		end

		def all_required
			req = @required_by.dup
			@required_by.each { |skill| req.concat skill.required_by }
			return req
		end

		def all_requires
			return [] if requires.nil? || requires.class == String
			return requires.all_requires << requires
		end

		def check_required
			required = self.all_required.collect { |skill| "\#remove_#{skill.name.sub(" ","_")}" }
			this = "\#remove_#{self.name.sub(" ","_")}"
			requires = self.all_requires.collect { |skill| "\#remove_#{skill.name.sub(" ","_")}"}
			return "check_if_selected(\"#{this}\", #{required.inspect}, #{requires.inspect})"
		end

		def check_required_inv
			required = self.all_required.collect { |skill| "\#add_#{skill.name.sub(" ","_")}" }
			this = "\#add_#{self.name.sub(" ","_")}"
			requires = self.all_requires.collect { |skill| "\#add_#{skill.name.sub(" ","_")}"}
			return "check_if_selected(\"#{this}\", #{requires.inspect}, #{required.inspect})"
		end

		def required_size
			return 1 if required_by.empty?
			length = -1
			required_by.each { |required| length += 1 + required.required_size }
			return length
		end

		def required_row(row_num)
			if row_num == 0
				return [self] if @required_by.empty?
				return [self].concat(@required_by[0].required_row(0))
			else
				child_num = 0
				while @required_by[child_num].required_size+1 <= row_num
					row_num -= @required_by[child_num].required_size+1
					child_num += 1
				end
				return [] if @required_by[child_num].required_size == row_num
				return @required_by[child_num].required_row(row_num)
			end
		end

		def invertible?
			@invertible
		end

		def dividible?
			@dividible
		end

		def attack?
			@effects.any? { |effect| effect.attack? }
		end

		def defend?
			@effects.any? { |effect| effect.defend? }
		end
	end

	class Ability
		attr_accessor :name, :full_text, :quick, :synergy

		@@abilities = nil

		def self.all
			if @@abilities == nil
				@@abilities = []
				XML::Parser.file('app/data/skills.xml').parse.root.find('Ability').each do |ability|
					@@abilities << Ability.new(ability)
				end
			end
			return @@abilities
		end

		def self.find_by_name(ability_name)
			Ability.all.detect { |ability| ability.name == ability_name }
		end

		def initialize(xml_node)
			@name = xml_node.find_first('Name').content
			@requires = xml_node.find_first('Require')
			@full_text = Skill.parse_text(xml_node.find_first('Text'))
			@quick = xml_node.find_first('Quick')
			@synergy = Synergy.new(xml_node.find_first('Synergy').content) if xml_node.find_first('Synergy')
		end

		def requires
			if @requires
				requires = ""
				@requires.each do |node|
					# requires << ", " if !requires.empty?
					if node.name == 'XP'
						if node.attributes['type'] == 'Spell'
							requires << "#{node.content} <span class=\"label label-inverse\">XP</span> Spent in Spells"
						else
							requires << "#{node.content} <span class=\"label label-inverse\">XP</span> Spent"
						end
					elsif Skill.all.any? { |skill| skill.name == node.content } ||
						Ability.all.any? { |ability| ability.name == node.content }
						requires << "<span class=\"label\">#{node.content}</span>"
					else
						requires << node.content
					end
				end
				return requires
			end
		end

		def require_xml
			return @requires
		end
		
		def quick
			return @quick_text if @quick_text
			@quick_text = Skill.parse_text(@quick).gsub(/<\/?p>/, '').html_safe
		end

		def synergy_css(added_str = "")
			synergy_name = @synergy ? @synergy.css_class : "no-synergy"
			return "#{added_str}#{synergy_name}"
		end

	end

end
