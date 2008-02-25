class AudioFile < ActiveRecord::Base
  belongs_to :audible, :polymorphic => true

  AUDIBLE_CLASSES = [ 'ContentItem', 'Litgloss' ]

  has_attachment :storage => :file_system,
  :content_type => ['audio/mpeg', 'audio/x-ms-wma',
                    'audio/vnd.rn-realaudio', 'audio/x-wav',
                    'application/ogg',
                    'video/quicktime'],

  :size => 0.byte..20.megabytes,
  :path_prefix => "data/audio_files"

  validates_as_attachment

  # Returns the object that this image is attached to.  The type is 
  # not guaranteed, but if it was created properly should be one of 
  # the classes represented in IMAGEABLE_CLASSES.
  def heard_object
    return eval(self.audible_type.camelize).find(self.audible_id)
  end

  # Returns boolean value representing whether or not this is a
  # featured image.
  def featured?
    return heard_object.featured_audio_file == self
  end

  # Returns a boolean value representing whether this class is able to
  # be "audible".  Uses reflection to determine if a) the object is
  # in the constant AUDIBLE_CLASSES and b) the object that the
  # inquiry is being made about has a "to_phrase" method.
  def AudioFile.audible_class_string?( some_object_string )
    AUDIBLE_CLASSES.include?( some_object_string ) ||
      AUDIBLE_CLASSES.include?( some_object_string.camelize )
  end

  def readable_by?(user)
    return self.heard_object.readable_by?(user)    
  end

  def writable_by?(user)
    return self.heard_object.writable_by?(user)
  end
end
