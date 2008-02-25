class AddImageglossPreference < ActiveRecord::Migration
  def self.up
    add_column :litglosses, :imagegloss, :boolean, :default => false
  end

  def self.down
    remove_column :litglosses, :imagegloss
  end
end


