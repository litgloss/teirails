class SystemPage < ActiveRecord::Base
  belongs_to :menu_item
  belongs_to :content_item
end
