class AddContentItemTabName < ActiveRecord::Migration
  def self.up
    SystemSetting.create :key => "content_item_tab_name", :value => 
      "Catalog", :label => "Name that is displayed on Content Item Tab in menu"
  end

  def self.down
    s = SystemSetting.find_by_key("content_item_tab_name")
    s.destroy
  end
end


