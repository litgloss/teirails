module ContentItemHelper

  def get_content_item_type(content_item)
    results = []

    if content_item.private_clone?
      results << link_to("private clone", content_item_clone_path(content_item.parent, content_item))
    else
      if content_item.published?
        results << "published"
      else
        results << "private"
      end

      if content_item.has_system_page
        results << "system page"
      end
    end
    
    return results.join(", ")

  end
  
  # Returns the links that can be used to modify this content
  # item for a given user.
  def get_valid_item_links(content_item)
    links = []

    if logged_in?
      if current_user.can_act_as?("editor")
        links << link_to("Edit", edit_content_item_path(content_item))
        links << link_to("Images", 
                         images_path(:imageable_type => "content_item", 
                                     :imageable_id => content_item.id))
        links << link_to("Versions", 
                         content_item_versions_path(content_item))
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

  # Returns text for the content item footer, based on user permissions.
  def get_footer_options(content_item)
    links = []


    # Allow user to clone this item if they are able to act as 
    # contributors, and if this item isn't already a clone.
    if current_user.can_act_as?("contributor") && 
        content_item.parent_id.nil?
      links << link_to( 'create clone', content_item_clones_path(content_item),
                        :confirm => "Are you sure that you wish  to create " + 
                        "a clone of this content item into your personal work" +
                        "space?",
                        :method => :post )
    end

    if content_item.writable_by?(current_user)
      links << link_to("edit", edit_content_item_path(content_item))
      links << link_to("images", 
                       images_path(:imageable_type => "content_item", 
                                   :imageable_id => content_item.id))

      links << link_to("audio", 
                       audio_files_path(:audible_type => "content_item", 
                                       :audible_id => content_item.id))

      links << link_to("versions", 
                       content_item_versions_path(content_item))
      links << link_to("litglosses", 
                       content_item_litglosses_path(content_item))

    end

    if current_user.can_act_as?("editor") &&
        !content_item.private_clones.empty?
      links << link_to('view clones', content_item_clones_path(content_item))
    end

    if current_user.can_act_as?("administrator")
      links << link_to('delete', content_item_path(content_item),
                       :confirm => "Are you sure?",
                       :method => :delete)
    end
    
    
    links.join(" | ")
  end
  
  # Returns a string of authors separated by commas
  def get_authors(content_item)
    if !content_item.authors.empty?
      content_item.authors.join(", ")
    else
      "Unknown Author"
    end
  end

  # Wraps the title method of the content item
  # so that "Unknown Title" shows up in cases
  # where it doesn't exist in the TEI.
  def get_title(content_item)
    if content_item.title.nil? || content_item.title.empty?
      "Unkown Title"
    else
      content_item.title
    end
  end
end
