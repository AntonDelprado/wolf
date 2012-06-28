class RemoveSkillsFromCharacters < ActiveRecord::Migration
  def up
    remove_column :characters, :skills
      end

  def down
    add_column :characters, :skills, :text
  end
end
