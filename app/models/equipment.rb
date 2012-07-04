# == Schema Information
#
# Table name: equipment
#
#  id           :integer         not null, primary key
#  character_id :integer
#  slot         :string(255)
#  name         :string(255)
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#  item_type    :string(255)
#

class Equipment < ActiveRecord::Base
	attr_accessible :character_id, :slot, :name, :item_type
	belongs_to :character, touch: true

	validates :character_id, presence: true
	validates :name, presence: true
	validates :slot, presence: true, inclusion: ['Primary', 'Off Hand', 'Armour']
	validates :item_type, presence: true, inclusion: ['Weapon', 'Shield', 'Armour']

	@@armours = @@shields = @@weapons = nil

	def self.weapons
		self.weapon_data.collect { |name, data| Equipment.new name: name, item_type: 'Weapon' }
	end

	def self.armours
		self.armour_data.collect { |name, data| Equipment.new name: name, item_type: 'Armour' }
	end

	def self.shields
		self.shield_data.collect { |name, data| Equipment.new name: name, item_type: 'Shield' }
	end

	def self.equip(character, slot, name)
		Equipment.find_all_by_character_id_and_slot(character.id, slot).each(&:delete)

		item_type = case
		when armour_data.has_key?(name) then 'Armour'
		when weapon_data.has_key?(name) then 'Weapon'
		when shield_data.has_key?(name) then 'Shield'
		end

		Equipment.create name: name, slot: slot, item_type: item_type, character_id: character.id
	end

	def requirements
		data[:require]
	end

	def one_handed?
		data[:hands] == 1
	end

	def two_handed?
		data[:hands] == 2
	end

	def hands
		data[:hands]
	end

	def weapon_class
		data[:weapon_class] if item_type == 'Weapon'
	end

	def dr
		data[:effect][:dr].to_i if data.has_key? :effect
	end

	def bonus
		data[:bonus]
	end

	def damage
		data[:damage]
	end

	def range
		data[:range]
	end

	def str_mod
		data[:effect][:str] if data.has_key? :effect
	end

	def str_mod
		data[:effect][:str] if data.has_key? :effect
	end
	
	def dex_mod
		data[:effect][:dex] if data.has_key? :effect
	end
	
	def int_mod
		data[:effect][:int] if data.has_key? :effect
	end
	
	def fai_mod
		data[:effect][:fai] if data.has_key? :effect
	end

	def quick
		data[:quick]
	end

	def skill_bonus(skill_name)
		data[:effect][skill_name] if data.has_key? :effect
	end

	private

	def data
		case self.item_type
		when 'Weapon' then self.class.weapon_data[self.name]
		when 'Shield' then self.class.shield_data[self.name]
		when 'Armour' then self.class.armour_data[self.name]
		end
	end

	def self.parse_require(require_xml)
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

	def self.parse_effect(effect_xml)
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

	def self.armour_data
		unless @@armours
			@@armours = {}
			XML::Parser.file('app/data/skills.xml').parse.root.find('Armour').each do |armour_xml|
				armour = { name: armour_xml.find_first('Name').content }
				armour[:require] = self.parse_require armour_xml.find_first('Require') if armour_xml.find_first('Require')
				armour[:effect] = self.parse_effect armour_xml.find_first('Effect') if armour_xml.find_first('Effect')
				armour[:quick] = armour_xml.find_first('Quick').content if armour_xml.find_first('Quick')
				armour[:quick] ||= ""

				@@armours[armour[:name]] = armour
			end
		end

		@@armours
	end

	def self.weapon_data
		unless @@weapons
			@@weapons = {}
			XML::Parser.file('app/data/skills.xml').parse.root.find('Weapon').each do |weapon_xml|
				weapon = {
					name:  			weapon_xml.find_first('Name').content,
					hands:  		weapon_xml.find_first('Hands').content.to_i,
					weapon_class:   weapon_xml.find_first('Class').content,
					damage:			weapon_xml.find_first('Damage').content,
					bonus:  		weapon_xml.find_first('Bonus').content.to_i,
				}
				weapon[:range] = weapon_xml.find_first('Range').content if weapon_xml.find_first('Range')

				weapon[:require] = self.parse_require weapon_xml.find_first('Require') if weapon_xml.find_first('Require')
				weapon[:effect] = self.parse_effect weapon_xml.find_first('Effect') if weapon_xml.find_first('Effect')
				weapon[:quick] = weapon_xml.find_first('Quick').content if weapon_xml.find_first('Quick')
				weapon[:quick] ||= ""
				
				@@weapons[weapon[:name]] = weapon
			end
		end

		@@weapons
	end

	def self.shield_data
		unless @@shields
			@@shields = {}
			XML::Parser.file('app/data/skills.xml').parse.root.find('Shield').each do |shield_xml|
				shield = { name: shield_xml.find_first('Name').content }
				shield[:require] = self.parse_require shield_xml.find_first('Require') if shield_xml.find_first('Require')
				shield[:effect] = self.parse_effect shield_xml.find_first('Effect') if shield_xml.find_first('Effect')
				shield[:quick] = shield_xml.find_first('Quick').content if shield_xml.find_first('Quick')
				shield[:quick] ||= ""

				@@shields[shield[:name]] = shield
			end
		end
		
		@@shields
	end
end
