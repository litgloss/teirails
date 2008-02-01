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

    # This is "weird," but we have to insert span tags
    # inside of the URL.  Use a regex, fix if this breaks...
    res.gsub(/>.*?</, "><span>#{link_text}</span><")
  end
end
