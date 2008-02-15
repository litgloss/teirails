class CreateSystemSettings < ActiveRecord::Migration
  def self.up
    create_table :system_settings do |t|
      t.string  :key
      t.text    :value
      t.string  :label
    end

    SystemSetting.Set("default_start_page", 1, 
                      "ID of sytem page to show to users " + 
                      "first on site visit")
  end

  def self.down
    drop_table :system_settings
  end
end
