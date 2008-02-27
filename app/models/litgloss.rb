class Litgloss < ActiveRecord::Base
  belongs_to :content_item
  belongs_to :creator, :class_name => "User"

  has_many :images, :as => :imageable, :dependent => :destroy
  has_many :audio_files, :as => :audible, :dependent => :destroy

  def writable_by?(user)
    return self.content_item.writable_by?(user)
  end

  def readable_by?(user)
    return self.content_item.readable_by?(user)
  end

  def Litgloss.to_phrase
    "litgloss"
  end

  # Returns the relative path to this litgloss.
  def path
    return "/litglosses/#{self.id}"
  end

  def url_encoded_explanation
    ERB::Util.url_encode(self.explanation)
  end
end
