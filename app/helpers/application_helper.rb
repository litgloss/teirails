module ApplicationHelper

  # Makes a link in the main application menu.  Use a style to keep it
  # darker if this is the current page.
  def make_menu_link(controller_name, restful_path_sym, link_text)
    current_controller = request.path_parameters['controller']

    res = nil

    if current_controller.eql?(controller_name.to_s)
      res = link_to(link_text, eval(restful_path_sym.to_s), :class => :curpage)
    else
      res = link_to(link_text, eval(restful_path_sym.to_s))
    end
    
    gsub_insert_span_tags(res, link_text)
  end

  # Returns a set of <li></li> items containing
  # user-specified menu items.
  def generate_system_menu_items
    current_controller = request.path_parameters['controller']

    menu_items = MenuItem.find(:all, :conditions => { :visible => true })
    
    res = []

    menu_items.each do |m|
      if current_controller.eql?("menu_items") &&
          params[:id].eql?(m.id.to_s)
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
