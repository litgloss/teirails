class Litgloss < ActiveRecord::Base
  belongs_to :content_item
  belongs_to :creator, :class_name => "User"
end
