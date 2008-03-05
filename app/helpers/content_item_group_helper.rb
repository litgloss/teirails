module ContentItemGroupHelper
  def get_index_item_options(group)
    links = []

    links << link_to('manage child pages', 
                     content_item_group_manage_positions_path(group))

    movement_links = get_movement_links( group )
    
    if !movement_links.empty?
      links << get_movement_links( group )
    end

    links.join(", ")
  end
end
