class MenuItem < ActiveRecord::Base
  acts_as_list

  has_many :system_pages, :order => "position"

  has_many :content_items, :through => :system_pages
end
