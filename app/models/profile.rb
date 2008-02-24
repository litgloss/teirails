class Profile < ActiveRecord::Base
  belongs_to :user
  has_one :image, :as => :imageable

  def readable_by?(user)
    # No protection!
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
