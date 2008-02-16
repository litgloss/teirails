# Contains meta-properties of a content item which is attached to a 
# 
class CreateSystemContentItems < ActiveRecord::Migration
  def self.up
    create_table :system_settings do |t|
      t.string  :key
      t.text    :value
      t.string  :label
    end

    SystemSetting.set("default_start_page", 1, 
                      "ID of sytem page to show to users " + 
                      "first on site visit")
  end

  def self.down
    drop_table :system_settings
  end
end
