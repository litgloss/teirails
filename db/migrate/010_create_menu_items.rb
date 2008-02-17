# Allows for menu items to be created for static site
# pages 
class CreateMenuItems < ActiveRecord::Migration
  def self.up
    create_table :menu_items do |t|
      t.string :name, :nil => false
      t.boolean :visible, :default => true
      t.integer :position
      t.timestamps
    end

  end

  def self.down
    drop_table :menu_items
  end
end
