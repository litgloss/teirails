class CreateSystemSettings < ActiveRecord::Migration
  def self.up
    create_table :system_settings do |t|
      t.string  :key, :nil => false
      t.string  :value
      t.string  :label
      
      t.timestamps
    end

    SystemSetting.create :key => "default_content_item", :value => 
      1, :label => "ID of default page to display to " +
      "users on site visit."

    SystemSetting.create :key => "site_name", :value => 
      "TeiRails", :label => "Primary name of site."
  end

  def self.down
    drop_table :system_settings
  end
end
