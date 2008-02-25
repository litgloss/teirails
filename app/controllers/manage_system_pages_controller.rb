# Allows user to re-arrange order of pages under a menu item.
class ManageSystemPagesController < ApplicationController
  append_before_filter :login_required

  before_filter :get_menu_item

  append_before_filter :get_system_page, :only => 
    [
     :move_higher,
     :move_lower,
     :move_to_top,
     :move_to_bottom
    ]

  def index
    @system_pages = @menu_item.system_pages
  end

  # Moves this element in the list to a higher position.
  def move_higher
    @system_page.move_higher
    @system_page.save
    flash[:notice] = "Element moved higher."
    redirect_to menu_item_manage_system_pages_path(@system_page.menu_item)
  end

  # Moves this element in the list to a lower position.
  def move_lower
    @system_page.move_lower
    @system_page.save
    flash[:notice] = "Element moved lower."
    redirect_to menu_item_manage_system_pages_path(@system_page.menu_item)
  end

  def move_to_top
    @system_page.move_to_top
    @system_page.save
    flash[:notice] = "Element moved to top."
    redirect_to menu_item_manage_system_pages_path(@system_page.menu_item)
  end

  def move_to_bottom
    @system_page.move_to_bottom
    @system_page.save
    flash[:notice] = "Element moved to bottom."
    redirect_to menu_item_manage_system_pages_path(@system_page.menu_item)
  end


  protected

  def get_system_page
    @system_page = SystemPage.find(params[:id])
  end

  def get_menu_item
    @menu_item = MenuItem.find(params[:menu_item_id])
  end

  private
  def authorized?
    current_user.can_act_as?("administrator")
  end
end
