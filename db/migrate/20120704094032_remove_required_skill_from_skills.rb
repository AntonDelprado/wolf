class RemoveRequiredSkillFromSkills < ActiveRecord::Migration
  def up
    remove_column :skills, :required_skill
      end

  def down
    add_column :skills, :required_skill, :string
  end
end
