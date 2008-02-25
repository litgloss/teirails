module MenuItemHelper
  def get_index_item_options(menu_item)
    links = []

    links << link_to('manage child pages', 
                     menu_item_manage_system_pages_path(menu_item))

    movement_links = get_movement_links( menu_item )
    
    if !movement_links.empty?
      links << link_to(get_movement_links( menu_item ))
    end

    links.join(", ")
  end
end
