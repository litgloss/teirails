class ContentItemGroupLink < ActiveRecord::Base
  validates_uniqueness_of :content_item_id, :scope => :content_item_group_id

  acts_as_list :scope => :content_item_group

  belongs_to :content_item
  belongs_to :content_item_group
end
