module ContentItemGroupLinkHelper
  def get_index_item_options(ci_group_link)
    links = []


    links << link_to('delete',
                     content_item_group_link_path(@content_item_group, ci_group_link),
                     :confirm => "Are you sure?", :method => :delete)
    
    movement_links = get_movement_links( ci_group_link )
    
    if !movement_links.empty?
      links << get_movement_links( group )
    end

    links.join(", ")
  end
end
