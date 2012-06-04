class CreateCharacters < ActiveRecord::Migration
  def change
    create_table :characters do |t|
      t.string :name
      t.string :player
      t.integer :str
      t.integer :dex
      t.integer :int
      t.integer :fai
      t.text :skills
      t.text :abilities

      t.timestamps
    end
  end
end
