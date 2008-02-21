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
    
    if !ContentItem.find_by_id(ci_int).nil?
      redirect_to content_item_path(ContentItem.find(ci_int))
    else
      redirect_to content_items_path
    end
  end
end
