module ApplicationHelper


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
    if current_controller.eql?("manage_system_pages")
      restful_part = "menu_item_manage_system_page_path"
      id_string = "#{element.menu_item.id}, #{element.id}"
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
        # Add links for top, bottom, higher, lower
        links << move_higher_link(element, restful_part, id_string)
        links << move_lower_link(element, restful_part, id_string)
        links << move_to_bottom_link(element, restful_part, id_string)
        links << move_to_top_link(element, restful_part, id_string)
      end
    end

    links.join(", ")
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
          !ContentItem.find(params[:id]).has_system_page) ||
         (current_controller.eql?("content_items") &&
          current_action.eql?("show") &&
          ContentItem.find(params[:id]).has_system_page &&
          ContentItem.find(params[:id]).system_page.menu_item.nil?
          )
         )

      res = link_to(link_text, eval(restful_path_sym.to_s), :class => :curpage)
    else
      res = link_to(link_text, eval(restful_path_sym.to_s))
    end
    
    gsub_insert_span_tags(res, link_text)
  end

  # Returns a list of <li></li> items for system sub menu.
  def generate_sub_menu_items
    current_controller = request.path_parameters['controller']

    links = []

    # If we're working on the user-generated menu items, 
    # figure out which object we're working on and pull in
    # all relevant content items.
    case current_controller
    when "menu_items"
      links = get_menu_item_submenu_links
    when "content_items"
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

    menu_items = MenuItem.find(:all, :conditions => { :visible => true },
                               :order => "position")
    
    res = []

    menu_items.each do |m|
      if current_controller.eql?("menu_items") &&
          params[:id].eql?(m.id.to_s) || 
        current_controller.eql?("content_items") &&
          current_action.eql?("show") &&
          ContentItem.find(params[:id]).has_system_page &&
          ContentItem.find(params[:id]).system_page.menu_item == m
        menu_item = link_to(m.name, menu_item_path(m), :class => :curpage)
      else
        menu_item = link_to(m.name, menu_item_path(m))
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

  def get_content_item_submenu_links
    links = []

    # If this content item is a system page, run method to
    # create submenu links instead of content item links.
    if !@content_item.nil? && @content_item.has_system_page &&
        !@content_item.system_page.menu_item.nil?
      links = get_menu_item_submenu_links(true)
    else
      links << get_ci_submenu_by_author_link
      links << get_ci_submenu_by_language_link
      links << get_ci_submenu_by_title_link
    end

    links
  end

  def get_menu_item_submenu_links(content_item_selected = false)
    links = []

    mi = nil

    if content_item_selected
      mi = @content_item.system_page.menu_item
    else
      if params[:id]
        mi = MenuItem.find(params[:id])      
      end
    end

    if !mi.nil?
      s_pgs = mi.system_pages.find(:all, :order => "position")
      cis = []

      s_pgs.each do |sp|
        cis << sp.content_item
      end

      cis.each do |c|
        links << link_to(c.title, content_item_path(c))
      end
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
