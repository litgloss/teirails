# Allows users to associate a system page with a menu item.
class MenuItemSelectionsController < ApplicationController
  before_filter :find_menu_item, :only => [:update]
  append_before_filter :find_content_item

  def index
  end

  def update
    sp = @content_item.system_page
    
    sp.menu_item = @menu_item

    if sp.save
      flash[:notice] = "New menu page set for content item."
    else
      flash[:error] = "Failed to save menu item for content item."
    end

    redirect_to content_item_path(@content_item)
  end

  protected
  def find_menu_item
    @menu_item = MenuItem.find(params[:id])
  end

  def find_content_item
    @content_item = ContentItem.find(params[:content_item_id])
  end
end
