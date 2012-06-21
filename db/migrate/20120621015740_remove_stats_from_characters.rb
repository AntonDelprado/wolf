class RemoveStatsFromCharacters < ActiveRecord::Migration
  def up
    remove_column :characters, :str_mod
        remove_column :characters, :dex_mod
        remove_column :characters, :int_mod
        remove_column :characters, :fai_mod
      end

  def down
    add_column :characters, :fai_mod, :integer
    add_column :characters, :int_mod, :integer
    add_column :characters, :dex_mod, :integer
    add_column :characters, :str_mod, :integer
  end
end
