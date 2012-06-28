class RemoveAbilitiesFromCharacters < ActiveRecord::Migration
  def up
    remove_column :characters, :abilities
      end

  def down
    add_column :characters, :abilities, :text
  end
end
