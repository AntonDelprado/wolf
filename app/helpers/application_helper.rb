require 'xml'

module ApplicationHelper

	def full_title(page_title, rules_title)
		base_title = "Wolf RPG"
		if rules_title
			return "#{base_title} | #{rules_title} Rules"
		elsif page_title
			return "#{base_title} |  #{page_title}"
		else
			return base_title
		end
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
		"<span class=\"label\">#{skill_name}</span>".html_safe
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

	def synergy_colours
		return {
			warrior:		'#fdd',
			rogue:			'#ddf',
			channeller:		'#ffd',
			mechanist:		'#eee',
			trickster:		'#fff1d8',
			battle_mage:	'#fdf',
			necromancer:	'#dfd',
			none:			'#ddd',
		}
	end

	class Effect
		attr_accessor :quick
		def initialize(xml_node)
			@quick_raw = xml_node.find_first('Quick')
			@mana = xml_node.find_first('Mana').content if xml_node.find_first('Mana')
			@power = xml_node.find_first('Power')

			if xml_node.find_first('Action')
				case xml_node.find_first('Action').content.downcase
				when 'major' then @action = :major_action
				when 'minor' then @action = :minor_action
				when 'attack' then @action = :attack_action
				when 'defend' then @action = :defend_action
				end
			end
		end

		def attack?
			@action == :attack_action
		end

		def defend?
			@action == :defend_action
		end

		def quick
			return @quick_text if @quick_text
			@quick_text = Skill.parse_text(@quick_raw).html_safe
		end

		def power(skills = nil, stats = nil)
			# Calculate the power given the skills and stats.
		end
	end

	class Skill
		attr_accessor :name, :name_inv, :stat, :cost, :full_text, :effects, :synergy, :spell, :requires

		@@skills = nil

		def self.all
			if @@skills == nil
				@@skills = []
				XML::Parser.file('public/skills.xml').parse.root.find('Skill').each do |skill|
					@@skills << Skill.new(skill)
				end
			end
			return @@skills
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
					stat = node.attributes['type'].capitalize
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

			# Find the effects
			@effects = []
			xml_node.find('Effect').each do |effect|
				@effects << Effect.new(effect)
			end

			# Find the synergy group
			if xml_node.find_first('Synergy')
				@synergy = case xml_node.find_first('Synergy').content
				when 'Warrior' then :warrior
				when 'Rogue' then :rogue
				when 'Channeller' then :channeller
				when 'Mechanist' then :mechanist
				when 'Trickster' then :trickster
				when 'Battle Mage' then :battle_mage
				when 'Necromancer' then :necromancer
				end
			end

			if xml_node.find_first('Spell')
				@spell = case xml_node.find_first('Spell').content
				when 'Arthur' then :arthur
				when 'Innodi' then :innodi
				when "Ird'ken" then :irdken
				when 'Oxdoro' then :oxdoro
				when 'Loreanna' then :loreanna
				end
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

		def synergy_name
			return 'Warrior' if @synergy == :warrior
			return 'Rogue' if @synergy == :rogue
			return 'Channeller' if @synergy == :channeller
			return 'Mechanist' if @synergy == :mechanist
			return 'Trickster' if @synergy == :trickster
			return 'Battle Mage' if @synergy == :battle_mage
			return 'Necromancer' if @synergy == :necromancer
		end

		def synergy_colour
			return {
				warrior:		'#fdd',
				rogue:			'#ddf',
				channeller:		'#ffd',
				mechanist:		'#eee',
				trickster:		'#fff1d8',
				battle_mage:	'#fdf',
				necromancer:	'#dfd',
				none:			'#ddd',
				}[@synergy] if @synergy
			return '#ddd'
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
		attr_accessor :name, :full_text, :quick

		@@abilities = nil

		def self.all
			if @@abilities == nil
				@@abilities = []
				XML::Parser.file('public/skills.xml').parse.root.find('Ability').each do |ability|
					@@abilities << Ability.new(ability)
				end
			end
			return @@abilities
		end

		def initialize(xml_node)
			@name = xml_node.find_first('Name').content
			@requires = xml_node.find_first('Require')
			@full_text = Skill.parse_text(xml_node.find_first('Text'))
			@quick = xml_node.find_first('Quick')
			if xml_node.find_first('Synergy')
				@synergy = case xml_node.find_first('Synergy').content
				when 'Warrior' then :warrior
				when 'Rogue' then :rogue
				when 'Channeller' then :channeller
				when 'Mechanist' then :mechanist
				when 'Trickster' then :trickster
				when 'Battle Mage' then :battle_mage
				when 'Necromancer' then :necromancer
				end
			end
		end

		def synergy_colour
			return {
				warrior:		'#fdd',
				rogue:			'#ddf',
				channeller:		'#ffd',
				mechanist:		'#eee',
				trickster:		'#fff1d8',
				battle_mage:	'#fdf',
				necromancer:	'#dfd',
				none:			'#ddd',
				}[@synergy] if @synergy
			return '#ddd'
		end

		def synergy_name
			return 'Warrior' if @synergy == :warrior
			return 'Rogue' if @synergy == :rogue
			return 'Channeller' if @synergy == :channeller
			return 'Mechanist' if @synergy == :mechanist
			return 'Trickster' if @synergy == :trickster
			return 'Battle Mage' if @synergy == :battle_mage
			return 'Necromancer' if @synergy == :necromancer
		end

		def requires
			if @requires
				requires = ""
				@requires.each do |node|
					# requires << ", " if !requires.length.zero?
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
	end

end
