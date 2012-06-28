class AddActivesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :active_character_id, :integer
    add_column :users, :character2_id, :integer
    add_column :users, :character3_id, :integer
    add_column :users, :active_campaign_id, :integer
    add_column :users, :campaign2_id, :integer
    add_column :users, :campaign3_id, :integer
  end
end
