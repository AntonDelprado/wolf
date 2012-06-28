class RenameClassToEquipment < ActiveRecord::Migration
	def up
		remove_column :equipment, :class
		add_column :equipment, :weapon_class, :string
	end

	def down
		remove_column :equipment, :weapon_class
		add_column :characters, :class, :string
	end
end
