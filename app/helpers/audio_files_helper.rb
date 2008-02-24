module AudioFilesHelper
  # Prints options for a list of audio file, e.g., add audio file to list if 
  # the current user has permissions.
  def audio_file_list_options_for_editors(associated_object)

    links = []

    if associated_object.writable_by?(current_user)
      links << link_to("Add new audio file",
                       new_audio_file_path(:audible_type => 
                                           associated_object.class.
                                           table_name.singularize, 
                                           :audible_id => associated_object.id))
    end

    links.join(", ")
  end

  # Prints editing options for a single element of the list of audio files if the
  # current user has permissions
  def list_item_options(audio_file)
    options = []

    options << link_to('View details', :action => 'show', :id => audio_file)
    options <<  link_to('Listen', stream_audio_file_path(audio_file),
		:popup => [ 'Audio Player', 'width=300, height=100' ])

    if logged_in? && audio_file.writable_by?(current_user)
      options << link_to('Delete', {:action => :destroy, :id => audio_file}, :method => 
                         :post, :confirm => "Are you sure?")
      options << link_to('Edit', :action => :edit, :id => audio_file)
    end
    
    return "(" + options.join(" | ") + ")"
  end

  # Prints the name of the audio file, or "Audio file unnamed."
  def printable_name(audio_file)
    if !audio_file.title.empty?
      return audio_file.title
    else
      return "This audio file is unnamed."
    end
  end

  # Prints the description of the audio file, or "No description available."
  def printable_description(audio_file)
    if !audio_file.description.empty?
      return audio_file.description
    else
      return "No description available."
    end
  end
end
