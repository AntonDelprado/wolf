class CreateAbilities < ActiveRecord::Migration
  def change
    create_table :abilities do |t|
      t.integer :character_id
      t.string :name

      t.timestamps
    end
  end
end
