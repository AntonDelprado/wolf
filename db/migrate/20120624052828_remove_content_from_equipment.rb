class RemoveContentFromEquipment < ActiveRecord::Migration
  def up
    remove_column :equipment, :type
        remove_column :equipment, :str_req
        remove_column :equipment, :dex_req
        remove_column :equipment, :hands
        remove_column :equipment, :damage
        remove_column :equipment, :dr
        remove_column :equipment, :bonus
        remove_column :equipment, :dex_mod
        remove_column :equipment, :range
        remove_column :equipment, :weapon_class

        add_column :equipment, :item_type, :string
      end

  def down
    add_column :equipment, :weapon_class, :string
    add_column :equipment, :range, :integer
    add_column :equipment, :dex_mod, :integer
    add_column :equipment, :bonus, :integer
    add_column :equipment, :dr, :integer
    add_column :equipment, :damage, :string
    add_column :equipment, :hands, :integer
    add_column :equipment, :dex_req, :integer
    add_column :equipment, :str_req, :integer
    add_column :equipment, :type, :string

    remove_column :equipment, :item_type
  end
end
