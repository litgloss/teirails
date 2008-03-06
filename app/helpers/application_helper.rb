module ApplicationHelper

  # include_ie_stylesheet_if_necessary: Includes an
  # Internet-Explorer-specific CSS file if the user is on MS/IE.  It
  # is incredible to think about how much developer time Microsoft has
  # wasted due to shoddy adherence to standards.  But, I guess that
  # this is what happens when profit continually trumps the desire to
  # create useful tools.
  def include_ie_stylesheet_if_necessary
    # Modify output for brain-dead browsers.
    if request.user_agent.downcase =~ /msie/
      return stylesheet_link_tag("ie_hacks")
    end
  end

  def form_end_tag
    "</form>"
  end

  # Changes all underscores to spaces in a word.
  def underscores_to_spaces(term)
    return term.gsub(/_/, ' ')
  end

  # Returns a set of links, joined by a comma, which
  # allow this element to move up or down in a list.
  # Input is an element of an object that acts_as_list.
  def get_movement_links(element)
    
    # Raise an exception if this thing isn't a list.
    if !element.class.ancestors.include?(ActiveRecord::Acts::List)
      raise Exception.new("Tried to get movement links for a class " + 
                          "that isn't a list!")
      return nil
    end
    
    links = []

    current_controller = request.path_parameters['controller']

    # Use custom path prefix if we are in manage_system_pages,
    # since this is a nested route.  Otherwise we default to
    # something based on class name.
    restful_part = nil
    id_string = ""
    if current_controller.eql?("content_item_group_links")
      restful_part = "content_item_group_link_path"
      id_string = "#{element.content_item_group.id}, #{element.id}"
    else
      restful_part = element.class.table_name.singularize +
        "_path"
      id_string = element.id
    end

    if element.first? && !element.last?
      # Add link to move object to beginning or higher
      links << move_lower_link(element, restful_part, id_string)
      links << move_to_bottom_link(element, restful_part, id_string)
    elsif element.last? && !element.first?
      links << move_higher_link(element, restful_part, id_string)
      links << move_to_top_link(element, restful_part, id_string)
    else
      if !(element.first? && element.last?)
        # Add links for top, bottom, higher, lower.  Skip the links to
        # move higher and lower if this element is first or last.
        
        links << move_higher_link(element, restful_part, id_string)
        links << move_lower_link(element, restful_part, id_string)
        links << move_to_bottom_link(element, restful_part, id_string)
        links << move_to_top_link(element, restful_part, id_string)
      end
    end

    
    if !links.empty?
      links.join(", ")
    else
      return "no movement options available"
    end
  end

  # Makes a link in the main application menu.  Use a style to keep it
  # darker if this is the current page.
  def make_menu_link(controller_name, restful_path_sym, link_text)
    current_controller = request.path_parameters['controller']
    current_action = request.path_parameters['action']

    res = nil

    # Usually we change the style of the current tab, unless it is 
    # a content item which is also a system_page.  Also if this
    # is a content page which is a system page but which has no reference
    # to a menu item, highlight it as current.
    if current_controller.eql?(controller_name.to_s) && 
        (!(current_controller.eql?("content_items") &&
           current_action.eql?("show")) ||
         (current_controller.eql?("content_items") &&
          current_action.eql?("show") &&
          !ContentItem.find(params[:id]).system?) ||
         (current_controller.eql?("content_items") &&
          current_action.eql?("show") &&
          ContentItem.find(params[:id]).system? &&
          ContentItem.find(params[:id]).groups.empty?
          )
         )

      res = link_to(link_text, eval(restful_path_sym.to_s), :class => :curpage)
    else
      res = link_to(link_text, eval(restful_path_sym.to_s))
    end
    
    gsub_insert_span_tags(res, link_text)
  end

  def generate_sub_menu_items
    current_controller = request.path_parameters['controller']

    links = []

    if current_controller =~ /^content_items$/
      links = get_content_item_submenu_links
    end

    # Surround links with <li></li> tags.
    i = 0
    links.each do |l|
      links[i] = "<li>" + l + "</li>"
      i += 1
    end
    
    links.join("\n")
  end

  # Returns a set of <li></li> items containing
  # user-specified menu items.
  def generate_system_menu_items
    current_controller = request.path_parameters['controller']
    current_action = request.path_parameters['action']

    cigs = ContentItemGroup.find(:all, :conditions => { 
                                         :visible => true,
                                         :system => true
                                       },
                                       :order => "position")
    
    res = []

    cigs.each do |m|
      if current_controller.eql?("content_item_groups") &&
          params[:id].eql?(m.id.to_s) || 
        current_controller.eql?("content_items") &&
          current_action.eql?("show") &&
          ContentItem.find(params[:id]).system? &&
          ContentItem.find(params[:id]).groups.include?(m)
        menu_item = link_to(m.name, content_item_group_path(m), :class => :curpage)
      else
        menu_item = link_to(m.name, content_item_group_path(m))
      end
      
      menu_item = gsub_insert_span_tags(menu_item, m.name)
      menu_item = "<li>" + menu_item + "</li>"
      res.push(menu_item)
    end

    res.join("\n")
  end

  # There was a patch for label_tag to the rails core,
  # but it was only on Jan 14 2008... until it's included, we'll
  # use our own.
  def label_tag(label, for_element)
    "<label for=\"#{for_element}\">#{label}</label>"
  end

  protected
  # This is "weird," but we have to insert span tags
  # inside of the URL.  Use a regex, fix if this breaks.
  def gsub_insert_span_tags(original_link, link_text)
    return original_link.gsub(/>.*?</, "><span>#{link_text}</span><")
  end

  # Displays an appropriate sub menu based on whether we are looking at 
  # a content item or a catalog page.
  def get_content_item_submenu_links
    current_action = request.path_parameters['action']

    links = []

    if current_action.eql?("show")
      if !@content_item.nil?
        links = get_content_item_group_submenu_links(@content_item)
      end

    elsif current_action =~ /^(index|by_author|by_title|by_language)$/
      links << get_ci_submenu_by_author_link
      links << get_ci_submenu_by_language_link
      links << get_ci_submenu_by_title_link
    end

    links
  end

  # Returns links to other content items in the group that was 
  # specified with this resource.
  def get_content_item_group_submenu_links(content_item)
    links = []

    # If there is only one group that this content item is 
    # associated with, show other items in that group.
    group_id = params[:group]
    if content_item.groups.size == 1
      group_id = content_item.groups[0].id
    end

    if group_id
      content_item_group = ContentItemGroup.find(group_id)      
      content_item_group.content_items.each do |c|
        links << link_to(c.title, content_item_path(c, :group => group_id))
      end
    elsif !content_item.groups.empty?
      content_item.groups.each do |cig|
        links << link_to("#{cig.name} group", content_item_group_path(cig))
      end
    else
      links << link_to(content_item.title, content_item_path(content_item))
    end

    links
  end

  def move_higher_link(element, restful_part, id_string)
    path_string = "move_higher_" + restful_part + "(#{id_string})"
    link_to("move higher", eval(path_string), :method => :post)
  end

  def move_lower_link(element, restful_part, id_string)
    path_string = "move_lower_" + restful_part + "(#{id_string})"
    link_to("move lower", eval(path_string), :method => :post)
  end

  def move_to_top_link(element, restful_part, id_string)
    path_string = "move_to_top_" + restful_part + "(#{id_string})"
    link_to("move to top", eval(path_string), :method => :post)
  end

  def move_to_bottom_link(element, restful_part, id_string)
    path_string = "move_to_bottom_" + restful_part + "(#{id_string})"
    link_to("move to bottom", eval(path_string), :method => :post)
  end

  # Used to maintain a filter that was applied previously on content 
  # items through state changes.
  def get_previous_filter
    if params[:filter]
      action = params[:filter]
    else
      action = request.path_parameters['action']
    end

    no_param_actions = [ "index", "by_author", "by_language", "by_title" ]

    if no_param_actions.include?(action)
      return { }
    else
      if action.eql?("search")
        return get_search_field_params
      else
        return { :filter => action }
      end
    end
  end

  def get_ci_submenu_by_author_link
    link_to "by author", by_author_content_items_url(get_previous_filter)
  end

  def get_ci_submenu_by_language_link
    action = request.path_parameters['action']

    link_to "by language", by_language_content_items_path(get_previous_filter)
  end

  def get_ci_submenu_by_title_link
    action = request.path_parameters['action']

    link_to "by title", by_title_content_items_path(get_previous_filter)
  end

  def get_search_field_params
    search_parts = [:titles, :authors, :bodies]
    search_params = { }

    search_parts.each do |sp|
      if params.include?(sp)
        search_params[sp] = 'on'
      end
    end

    search_params[:term] = params[:term]

    search_params[:filter] = "search"

    return search_params
  end
end
