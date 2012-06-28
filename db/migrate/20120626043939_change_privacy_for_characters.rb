class ChangePrivacyForCharacters < ActiveRecord::Migration
  def up
  	remove_column :characters, :visibility
    add_column :characters, :privacy, :integer
  end

  def down
    add_column :characters, :visibility, :string
    remove_column :characters, :privary
  end
end
