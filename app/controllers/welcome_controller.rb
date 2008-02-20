class WelcomeController < ApplicationController

  def index

    # If there is no default setting, just go to CI index.
    if SystemSetting.get("default_content_item").nil?
      redirect_to content_items_path
      return
    end
    
    # If we have a content item page selected, route to that.
    # otherwise go to CI index.
    sp = SystemSetting.get("default_content_item")
    
    ci_int = eval(sp)
    
    cp = ContentItem.find(ci_int)
    
    if !cp.nil?
      redirect_to content_item_path(cp)
    else
      redirect_to content_items_path
    end
  end
end
