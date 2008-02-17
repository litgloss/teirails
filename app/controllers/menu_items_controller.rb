class MenuItemsController < ApplicationController

  before_filter :find_menu_item, :only => [:edit, :show, :update, :destroy]

  def index
    @menu_items = MenuItem.find(:all)
  end

  def new
    @menu_item = MenuItem.new
  end

  def show
  end

  def destroy
    if @menu_item.destroy
      flash[:notice] = "Menu item deleted."
      redirect_to menu_items_path
    else
      flash[:error] = "Unable to destroy menu item."
      redirect_to menu_items_path
    end
  end

  def update
    if @menu_item.update_attributes(params[:menu_item])
      flash[:notice] = 'Menu item details were successfully updated.'
      redirect_to menu_item_path(@menu_item)
    else
      flash[:error] = 'Failed to update menu item properties.'
      redirect_to menu_item_path(@menu_item)
    end
  end

  def create
    @menu_item = MenuItem.new(params[:menu_item])
    @menu_item.save!

    flash[:notice] = "New menu item created with name #{@menu_item.name}"
    redirect_to menu_items_path
  end

  protected
  def find_menu_item
    @menu_item = MenuItem.find(params[:id])
  end
end
