class CreateSystemPages < ActiveRecord::Migration
  def self.up
    create_table :system_pages do |t|
      t.integer :content_item_id
      t.integer :menu_item_id
      t.integer :position

      t.timestamps
    end

  end

  def self.down
    drop_table :system_pages
  end
end
