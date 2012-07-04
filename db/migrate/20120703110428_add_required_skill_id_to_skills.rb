class AddRequiredSkillIdToSkills < ActiveRecord::Migration
  def change
    add_column :skills, :required_skill_id, :integer
  end
end
