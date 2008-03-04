class CreateContentItemGroupLinks < ActiveRecord::Migration
  def self.up
    create_table :content_item_group_links do |t|
      t.integer :content_item_id

      t.integer :content_item_group_id

      t.integer :position

      t.timestamps
    end

  end

  def self.down
    drop_table :content_item_group_links
  end
end
