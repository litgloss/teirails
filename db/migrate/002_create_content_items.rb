class CreateContentItems < ActiveRecord::Migration
  def self.up
    create_table :content_items, :force => true do |t|
      t.text :tei_data

      t.integer :creator_id

      t.timestamps
    end
  end

  def self.down
    drop_table :content_items
  end
end
