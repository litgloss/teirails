class Image < ActiveRecord::Base
  belongs_to :imageable, :polymorphic => true

  belongs_to :creator, :class_name => "User", :foreign_key => :user_id

  has_attachment :content_type => :image,
  :storage => :file_system,
  :path_prefix => 'data',
  :max_size => 50.megabytes,
  :thumbnails => {
    :small => '100x100>',
    :medium => '450x450>',
    :large => '800x800>'
  }

  validates_as_attachment

  # For polymorphic class, copy attributes of parent into
  # self.
  def copy_attributes_from_parent
    if !self.parent.nil?
      self.imageable_type = self.parent.imageable_type
      self.imageable_id = self.parent.imageable_id
      self.user_id = self.parent.user_id
      self.save!
    end
  end

  after_attachment_saved do |image|
    image.copy_attributes_from_parent
  end

end
