module ApplicationHelper

  # Makes a link in the main application menu.  Use a style to keep it
  # darker if this is the current page.
  def make_menu_link(controller_name, restful_path_sym, link_text)
    current_controller = request.path_parameters['controller']
    current_action = request.path_parameters['action']

    res = nil

    # Usually we change the style of the current tab, unless it is 
    # a content item which is also a system_page.
    if current_controller.eql?(controller_name.to_s) && 
        (!(current_controller.eql?("content_items") &&
           current_action.eql?("show")) ||
         (current_controller.eql?("content_items") &&
          current_action.eql?("show") &&
          !ContentItem.find(params[:id]).has_system_page))

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
      mi = MenuItem.find(params[:id])
      cis = mi.content_items
      cis.each do |c|
        links << link_to("ci id #{c.id}", content_item_path(c))
      end
    
    when "content_items"
      links << "ci submenu"
    end

    # Surround links with <li></li> tags.
    i = 0
    links.each do |l|
      links[i] = "<li>" + l + "</li>"
      i += 1
    end

    links.join(" | ")
  end

  # Returns a set of <li></li> items containing
  # user-specified menu items.
  def generate_system_menu_items
    current_controller = request.path_parameters['controller']
    current_action = request.path_parameters['action']

    menu_items = MenuItem.find(:all, :conditions => { :visible => true })
    
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

  protected
  # This is "weird," but we have to insert span tags
  # inside of the URL.  Use a regex, fix if this breaks.
  def gsub_insert_span_tags(original_link, link_text)
    return original_link.gsub(/>.*?</, "><span>#{link_text}</span><")
  end
end
