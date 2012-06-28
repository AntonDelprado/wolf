class AddSynergyNameToCharacterSkills < ActiveRecord::Migration
  def change
    add_column :character_skills, :synergy_name, :string
  end
end
