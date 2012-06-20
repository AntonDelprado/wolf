class AddItemsAndVisibilityToCharacters < ActiveRecord::Migration
  def change
    add_column :characters, :items, :text
    add_column :characters, :visibility, :string
  end
end
