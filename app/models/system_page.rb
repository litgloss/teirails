class MenuItem < ActiveRecord::Base
  has_many :system_pages
  has_many :content_items, :through => :system_pages
end
