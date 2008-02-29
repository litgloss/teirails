class Profile < ActiveRecord::Base
  belongs_to :user
  has_one :image, :as => :imageable

  def readable_by?(user)
    # No protection on default object, but there are no methods to
    # view personal information -- just the description and image 
    # are considered public information in this table.
    true
  end

  def writable_by?(user)
    
    return case
           when self.user == user
             true
             
           when user.can_act_as?("administrator")
             true
             
           else
             false
             
           end
  end

end
