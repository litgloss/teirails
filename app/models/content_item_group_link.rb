class ContentItemGroupLink < ActiveRecord::Base
  acts_as_list :scope => :group

  belongs_to :content_item
  belongs_to :content_item_group
end
