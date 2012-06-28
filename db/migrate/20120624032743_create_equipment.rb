class CreateEquipment < ActiveRecord::Migration
  def change
    create_table :equipment do |t|
      t.integer :character_id
      t.string :slot
      t.string :name
      t.string :type
      t.integer :str_req
      t.integer :dex_req
      t.integer :hands
      t.string :class
      t.string :damage
      t.integer :dr
      t.integer :bonus
      t.integer :dex_mod
      t.integer :range

      t.timestamps
    end
  end
end
