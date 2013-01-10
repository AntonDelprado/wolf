require 'xml'
require 'string'

module ApplicationHelper

	def alert_icon(alert_type)
		return "<i class='icon-exclamation-sign'></i> ".html_safe if alert_type == 'error'
		return "<i class='icon-ok icon-white'></i> ".html_safe if alert_type == 'success'
		return "<i class='icon-warning-sign'></i> ".html_safe
	end

	def delete
		"<i class='icon-trash icon-white'></i> Delete".html_safe
	end

	def modify
		"<i class='icon-pencil icon-white'></i> Modify".html_safe
	end

	def export
		"<i class='icon-download-alt icon-white'></i> Export".html_safe
	end

	def page(type)
		"<i class='icon-book icon-white'></i> #{type} Page".html_safe
	end

	def add(type)
		"<i class='icon-plus icon-white'></i> Add #{type}".html_safe
	end

	def remove(type)
		"<i class='icon-minus icon-white'></i> Remove #{type}".html_safe
	end

	def change(type)
		"<i class='icon-resize-vertical icon-white'></i> Change #{type}".html_safe
	end

	def save_changes
		"<i class='icon-ok icon-white'></i> Save Changes".html_safe
	end

	def full_title(page_title = nil)
		base_title = "Wolf RPG"
		return "#{base_title} | #{page_title}" if page_title
	end

	def strength
		content_tag :span, "Strength", class: 'label label-success'
	end

	def dexterity
		content_tag :span, "Dexterity", class: 'label label-success'
	end

	def intelligence
		content_tag :span, "Intelligence", class: 'label label-success'
	end

	def faith
		content_tag :span, "Faith", class: 'label label-success'
	end

	def major_action
		content_tag :span, "Major Action", class: 'label label-inverse'
	end

	def minor_action
		content_tag :span, "Minor Action", class: 'label label-inverse'
	end

	def move_action
		content_tag :span, "Move Action", class: 'label label-inverse'
	end

	def damage_reduction(amount=nil)
		return content_tag :span, "DR", class: 'label' if amount.nil?
		return content_tag :span, "#{amount} DR", class: 'label'
	end

	def hp(amount = nil)
		return content_tag(:span, 'HP', class: 'label label-important') if amount.nil?
		return content_tag(:span, 'HP Max', class: 'label label-important') if amount == 'max'
		return content_tag(:span, "#{amount} HP", class: 'label label-important')
	end

	def mp(amount = nil)
		return content_tag(:span, 'MP', class: 'label label-info') if amount.nil?
		return content_tag(:span, 'MP Max', class: 'label label-info') if amount == 'max'
		return content_tag(:span, "#{amount} MP", class: 'label label-info')
	end

	def skill(skill_name)
		return content_tag :span, skill_name, class: 'label'
	end

	def rate(value)
		case
		when value == 0 then text = "1/ Turn"
		when value < 0 then text = "1/ #{2**(-value)} Turns"
		when value > 0 then text = "#{1+value} / Turn"
		end
	end

	def result_level(value)
		case
		when value <= 0 then 0
		when value <= 2 then 1
		when value <= 5 then 2
		when value <= 10 then 3
		when value <= 17 then 4
		when value <= 26 then 5
		when value <= 37 then 6
		else 7
		end
	end

	def result_name(value)
		case result_level(value)
		when 0 then 'Critical Failure'
		when 1 then 'Failure'
		when 2 then 'Basic Pass'
		when 3 then 'Pass'
		when 4 then 'Skillful Pass'
		when 5 then 'Prodigious Pass'
		when 6 then 'Epic Pass'
		when 7 then 'Godlike Pass'
		end
	end

	def check(skill_name, stat_name)
		content_tag :span, "#{skill_name.titleise}:#{stat_name.titleise}".html_safe, class: 'label label-warning'
	end

	def parse_text_xml(xml_text, type=:full)
		text = "<p class='popover-body'>"
		xml_text.each do |node|
			case node.name.downcase
			when 'text' then text << node.content.gsub("\n", '</p><p class="popover-body">')
			when 'half' then text << "&frac12"
			when 'third' then text << "&#8531"
			when 'times' then text << "&times;"
			when 'name'
				if node.content == 'Minor Action'
					text << minor_action
				elsif node.content == 'Major Action'
					text << major_action
				elsif node.content == 'Move Action'
					text << move_action
				elsif Skill.every.any? { |skill| skill.name == node.content || skill.inv_name == node.content } ||
					Ability.every.any? { |ability| ability.name == node.content }
					text << skill(node.content)
				else
					text << content_tag(:b, node.content)
				end
			when 'str', 'strength' then text << strength
			when 'dex', 'dexterity' then text << dexterity
			when 'int', 'intelligence' then text << intelligence
			when 'fai', 'faith' then text << faith
			when 'hp' then text << hp(node.content)
			when 'mp' then text << mp(node.content)
			when 'xp' then text << content_tag(:span, 'XP', class: 'label')
			when 'hpmax' then text << hp('max')
			when 'mpmax' then text << mp('max')
			when 'emph' then text << content_tag(:em, node.content)
			when 'check'
				stat = node.attributes['type'] ? node.attributes['type'].titleise : ""
				skill = ""
				node.each do |inner_node|
					if inner_node.name == 'times'
						skill << '&times;'
					else
						skill << inner_node.content
					end
				end
				text << check(skill, stat)

			else text << content_tag(:b, "#{node.content} *** (#{node.name})")
			end
		end

		return text.gsub(/<\/?p(\s[^>]*)?>/, '') unless type == :full
		return text + '</p>'
	end

	def popover_hp(character, index)
		[
			'Change HP By:',
			text_field_tag("hp_field_#{index}", "", class: 'hp-field', index: index, onchange: "update_hp(#{index})"),
		].join()
	end

	def popover_mp(character, index)
		[
			'Change MP By:',
			text_field_tag("mp_field_#{index}", "", class: 'mp-field', index: index, onchange: "update_mp(#{index})"),
		].join()
	end

	def popover_content(skill)
		return "<p class='popover-requires'>Requires: #{skill.required_skill.name}</p> <p class='popover-body'>#{parse_text_xml(skill.text)}</p>" unless skill.required_skill.nil?
		return "<p class='popover-body'>#{parse_text_xml(skill.text)}</p>"
	end

	def popover_title(skill)
		case skill.spell
		when 'Arthur' then "<span class='popover-title'>#{skill.full_name}</span> #{tag :img, src: '/assets/arthur.png', class: 'popover-spell'}"
		when 'Innodi' then "<span class='popover-title'>#{skill.full_name}</span> #{tag :img, src: '/assets/innodi.png', class: 'popover-spell'}"
		when "Ird'ken" then "<span class='popover-title'>#{skill.full_name}</span> #{tag :img, src: '/assets/irdken.png', class: 'popover-spell'}"
		when 'Oxdoro' then "<span class='popover-title'>#{skill.full_name}</span> #{tag :img, src: '/assets/oxdoro.png', class: 'popover-spell'}"
		when 'Loreanna' then "<span class='popover-title'>#{skill.full_name}</span> #{tag :img, src: '/assets/loreanna.png', class: 'popover-spell'}"
		else skill.name
		end
	end

	@@raw_monsters = nil

	class Monster
		attr_accessor :name, :hp, :str, :dex, :int, :fai, :attack, :attack_type, :defend, :defend_skill, :text
	end

	def monsters
		if @@raw_monsters.nil?
			@@raw_monsters = []

			XML::Parser.file('app/data/monsters.xml').parse.root.find('Monster').each do |monster_xml|
				monster = Monster.new
				monster.name = monster_xml.find_first('Name').content

				monster.hp = monster_xml.find_first('HP').try :content
				monster.str = monster_xml.find_first('Str') ? monster_xml.find_first('Str').content : 4
				monster.dex = monster_xml.find_first('Dex') ? monster_xml.find_first('Dex').content : 4
				monster.int = monster_xml.find_first('Int') ? monster_xml.find_first('Int').content : 4
				monster.fai = monster_xml.find_first('Fai') ? monster_xml.find_first('Fai').content : 4

				monster_xml.find('Attack').each do |attack_xml| # for now, ignore multiple attacks
					monster.attack = attack_xml.content
					monster.attack_type = attack_xml['type'] if attack_xml['type']
				end

				monster_xml.find('Defend').each do |defend_xml| # for now, ignore multiple defenses
					monster.defend = defend_xml.content
					monster.defend_skill = defend_xml['skill']
				end

				monster.text = parse_text_xml(monster_xml.find_first('Text'), :quick) if monster_xml.find_first('Text')

				@@raw_monsters << monster
			end

			@@raw_monsters.sort_by! { |monster| monster.name }
		end

		return @@raw_monsters
	end

end
