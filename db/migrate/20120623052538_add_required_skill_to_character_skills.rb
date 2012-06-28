class AddRequiredSkillToCharacterSkills < ActiveRecord::Migration
  def change
    add_column :character_skills, :required_skill, :string
  end
end
