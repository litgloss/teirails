class WelcomeController < ApplicationController

  def index

    # If the system hasn't been "installed" yet, redirect
    # to install page.
    if User.find(:all).empty?
      flash[:notice] = "You have been redirected to the system " +
        "installation routine.  You must set up the system with an " +
        "administrative user before other users are able to join."

      redirect_to new_install_path
      return
    end

    # If there is no default setting, just go to CI index.
    if SystemSetting.get("default_content_item").nil?
      redirect_to content_items_path
      return
    end
    
    # If we have a content item page selected, route to that.
    # otherwise go to CI index.
    sp = SystemSetting.get("default_content_item")
    
    ci_int = eval(sp)
    
    if !ContentItem.find_by_id(ci_int).nil?
      redirect_to content_item_path(ContentItem.find(ci_int))
    else
      redirect_to content_items_path
    end
  end
end
