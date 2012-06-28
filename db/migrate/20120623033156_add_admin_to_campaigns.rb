class AddAdminToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :admin_id, :integer
  end
end
