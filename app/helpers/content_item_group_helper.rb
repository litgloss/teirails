module ContentItemGroupHelper
  def get_index_item_options(group)
    links = []

    links << link_to('manage child pages', 
                     content_item_group_links_path(group))

    movement_links = get_movement_links( group )
    
    if !movement_links.empty?
      links << movement_links
    end

    links.join(", ")
  end
end
