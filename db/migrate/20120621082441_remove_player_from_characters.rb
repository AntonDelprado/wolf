class RemovePlayerFromCharacters < ActiveRecord::Migration
  def up
    remove_column :characters, :player
      end

  def down
    add_column :characters, :player, :string
  end
end
