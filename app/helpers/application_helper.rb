require 'xml'

module ApplicationHelper

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

	def check(skill_name, stat_name)
		content_tag :span, "#{skill_name.capitalize}:#{stat_name.capitalize}", class: 'label label-warning'
	end

	def parse_text_xml(xml_text, type=:full)
		text = "<p>"
		xml_text.each do |node|
			case node.name.downcase
			when 'text' then text << node.content.gsub("\n", '</p><p>')
			when 'half' then text << "&frac12"
			when 'third' then text << "&#8531"
			when 'times' then text << "&times;"
			when 'name'
				if node.content == 'Minor Action'
					text << minor_action
				elsif node.content == 'Major Action'
					text << major_action
				elsif Skill.all.any? { |skill| skill.name == node.content } ||
					Ability.all.any? { |ability| ability.name == node.content }
					text << skill(node.content)
				else
					text << content_tag(:b, node.content)
				end
			when 'str' then text << strength
			when 'dex' then text << dexterity
			when 'int' then text << intelligence
			when 'fai' then text << faith
			when 'hp' then text << hp(node.content)
			when 'mp' then text << mp(node.content)
			when 'xp' then text << content_tag(:span, 'XP', class: 'label')
			when 'hpmax' then text << hp('max')
			when 'mpmax' then text << mp('max')
			when 'emph' then text << content_tag(:em, node.content)
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
				text << check(skill, stat)

			else text << content_tag(:b, "#{node.content} *** (#{node.name})")
			end
		end

		return text.gsub(/<\/?p>/, '') unless type == :full
		return text + "</p>"
	end
end
