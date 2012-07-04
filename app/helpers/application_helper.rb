require 'xml'

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
		content_tag :span, "#{skill_name.capitalize}:#{stat_name.capitalize}".html_safe, class: 'label label-warning'
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
		return text + '</p>'
	end

	def popover_content(skill)
		return "<p class='bold'>Requires: #{skill.required_skill.name} #{parse_text_xml(skill.text)}" unless skill.required_skill.nil?
		return parse_text_xml(skill.text)
	end

	def popover_title(skill)
		case skill.spell
		when 'Arthur' then "#{skill.full_name} #{tag :img, src: '/assets/arthur.png', class: 'popover-spell'}"
		when 'Innodi' then "#{skill.full_name} #{tag :img, src: '/assets/innodi.png', class: 'popover-spell'}"
		when "Ird'ken" then "#{skill.full_name} #{tag :img, src: '/assets/irdken.png', class: 'popover-spell'}"
		when 'Oxdoro' then "#{skill.full_name} #{tag :img, src: '/assets/oxdoro.png', class: 'popover-spell'}"
		when 'Loreanna' then "#{skill.full_name} #{tag :img, src: '/assets/loreanna.png', class: 'popover-spell'}"
		else skill.name
		end
	end
end
