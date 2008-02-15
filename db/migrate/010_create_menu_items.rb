# Allows for a system menu and submenu that can be
# dynamically modified.
class CreateMenuItems < ActiveRecord::Migration
  def self.up
    create_table :menu_items do |t|
      t.string :name, :nil => false
      
      # Specifies the parent item of this menu if 
      # this item is in the submenu, nil otherwise.
      t.integer :parent_id

      # Specifies the order in which this item should 
      # be displayed in the appropriate menu.
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :menu_items
  end
end
