class CreateContentItems < ActiveRecord::Migration
  def self.up
    create_table :content_items, :force => true do |t|
      t.text :tei_data

      t.integer :creator_id
      t.boolean :published, :default => false

      # Item is protected for copyright or other reason.
      # If this is the case, user must have at least role of 
      # "protected item viewer" or higher to see it.
      t.boolean :protected, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :content_items
  end
end
