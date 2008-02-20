# SystemSettings acts as a global hashtable used to store system 
# configuration and running options.  We marshalize the incoming 
# key and "load" it coming out.  This allows us to store arbitrary
# data types in this database without losing type.
class SystemSetting < ActiveRecord::Base
  validates_uniqueness_of :key

  # Returns the value of a system setting with the specified key
  def SystemSetting.get(key)
    if !SystemSetting.find_by_key(key).nil?
      return SystemSetting.find_by_key(key).value
    else
      return nil
    end
  end

  # Returns the value of a label with the specified key
  def SystemSetting.label(key)
    if !SystemSetting.find_by_key(key).nil?
      return SystemSetting.find_by_key(key).label
    else
      return nil
    end
  end
end

