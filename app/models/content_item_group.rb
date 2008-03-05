class ContentItemGroup < ActiveRecord::Base
  acts_as_list :scope => 'system=\'#{system}\''

  has_many :content_item_group_links
  has_many :content_items, :through => :content_item_group_links

  # We don't have anything really important behind this object, since 
  # individual content item permissions are still protected.  Fill this
  # method in later as necessary.
  def readable_by?
    return true
  end

  def writable_by?
    if user.class == Symbol || user.nil?
      return false
    end
    
    return case 
           when self.system?
             user.can_act_as?("administrator")
             
           else
             user.can_act_as?("editor")
           end
  end
end
