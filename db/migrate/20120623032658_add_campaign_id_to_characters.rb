class AddCampaignIdToCharacters < ActiveRecord::Migration
  def change
    add_column :characters, :campaign_id, :integer
  end
end
