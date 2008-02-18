class SystemPage < ActiveRecord::Base
  acts_as_list :scope => :menu_item

  belongs_to :menu_item
  belongs_to :content_item
end
