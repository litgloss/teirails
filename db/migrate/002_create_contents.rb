class CreateContents < ActiveRecord::Migration
  def self.up
    create_table :contents, :force => true do |t|
      t.text :tei_data

      t.integer :creator_id

      t.timestamps
    end
  end

  def self.down
    drop_table :contents
  end
end
