class Litgloss < ActiveRecord::Base
  belongs_to :content_item
  belongs_to :creator, :class_name => "User"

  def writable_by?(user)
    return self.content_item.writable_by?(user)
  end
end
