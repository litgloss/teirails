class CreateLitglosses < ActiveRecord::Migration
  def self.up
    create_table :litglosses do |t|
      t.integer :content_item_id
      t.integer :creator_id
      
      t.string :term

      t.text :explanation

      t.integer :count

      t.timestamps
    end

  end

  def self.down
    drop_table :litglosses
  end
end
