class Profile < ActiveRecord::Base
  belongs_to :user
  has_one :photo, :as => :imageable
end
