class ContentItemGroup < ActiveRecord::Base
  acts_as_list :scope => 'system=\'#{system}\''

  has_many :content_item_group_links
  has_many :content_items, :through => :content_item_group_links
end
