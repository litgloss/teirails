# Adds fields for permissions to user model.  Allows us to have
# administrators and editors on the site.
class AddPermissionFieldsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :editor, :boolean, :default => false
    add_column :users, :administrator, :boolean, :default => false
  end

  def self.down
    remove_column :users, :editor
    remove_column :users, :administrator
  end
end
