module ContentItemHelper
  
  # Returns the links that can be used to modify this content
  # item for a given user.
  def get_valid_item_links(content_item)
    links = []

    if logged_in?
      if current_user.can_act_as?("editor")
        links << link_to("Edit", edit_content_item_path(content_item))
      end

      if content_item.has_system_page &&
          current_user.can_act_as?("administrator")
        links << link_to("Select Menu Item", 
                         content_item_menu_item_selections_path(content_item))
      end
    end
      
      if !links.empty?
        return "(" + links.join(", ") + ")"
      else
        return ""
      end
  end

  
  # Returns a string of authors separated by commas
  def get_authors(content_item)
    if !content_item.authors.empty?
      content_item.authors.join(", ")
    else
      "Author Unknown"
    end
  end
end
