# SystemSettings acts as a global hashtable used to store system 
# configuration and running options.  We marshalize the incoming 
# key and "load" it coming out.  This allows us to store arbitrary
# data types in this database without losing type.
class SystemSetting < ActiveRecord::Base
  validates_uniqueness_of :key

  # Gets the key with the value passed to us in the first parameter.
  def SystemSetting.get(key)
    record = Setting.find_by_key(name)

    if record.nil?
      return nil
    else
      return Marshal.load(record.value)      
    end
  end

  # Sets the key (parameter 1) to value (parameter 2).
  def SystemSetting.set(key, value, label = nil)
    record = Setting.find_by_key(key)
    
    if record.nil?
      record = Setting.new(:key => key)
    end
    
    record.value = Marshal.dump(value)

    record.save!
  end
end

