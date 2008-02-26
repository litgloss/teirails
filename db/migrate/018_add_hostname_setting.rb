class AddHostnameSetting < ActiveRecord::Migration
  def self.up
    SystemSetting.create :key => "hostname", :value => 
      "teirails.phq.org", :label => "Hostname and optional port of " + 
      "system that this instance of TeiRails is running on."
  end

  def self.down
    s = SystemSetting.find_by_key("hostname")
    s.destroy
  end
end


