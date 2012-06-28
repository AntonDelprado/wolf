class AddVisibilityToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :visibility, :string
  end
end
