# Allows for menu items to be created for static site
# pages 
class CreateContentItemGroups < ActiveRecord::Migration
  def self.up
    create_table :content_item_groups do |t|
      # String that is used for identification of this group
      t.string :name, :nil => false, :unique => true

      t.integer :position
      
      # Determines whether or not this content item group is 
      # a system content item group
      t.boolean :system, :default => false

      t.boolean :visible, :default => true

      t.timestamps
    end

  end

  def self.down
    drop_table :content_item_groups
  end
end
