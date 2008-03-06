module SystemSettingsHelper
  def get_type_options
    retval = ""

    options = ["Integer", "Boolean", "String"]
    
    i = 0
    options.each do |o|
      options[i] = "<option>#{o}</option>"
      i += 1
    end

    options.join("\n")
  end
end
