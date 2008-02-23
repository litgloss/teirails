class MenuItemsController < ApplicationController
  before_filter :find_menu_item, :only => [:edit, :show, :update, :destroy,
                                           :move_higher, :move_lower,
                                           :move_to_top, :move_to_bottom]

  append_before_filter :login_required, :except => [:show]

  def index
    @menu_items = MenuItem.find(:all, :order => :position)
  end

  def new
    @menu_item = MenuItem.new
  end

  def show
    if @menu_item.content_items.find(:all, :conditions => { 
                                       :published => true 
                                     }).size > 0
      redirect_to content_item_path(@menu_item.
                                    content_items.find(:first,
                                                       :conditions => {
                                                         :published => true
                                                       }))
      return
    end
  end

  # Moves this element in the list to a higher position.
  def move_higher
    @menu_item.move_higher
    @menu_item.save
    flash[:notice] = "Element moved higher."
    redirect_to menu_items_path
  end

  # Moves this element in the list to a lower position.
  def move_lower
    @menu_item.move_lower
    @menu_item.save
    flash[:notice] = "Element moved lower."
    redirect_to menu_items_path
  end

  def move_to_top
    @menu_item.move_to_top
    @menu_item.save
    flash[:notice] = "Element moved to top."
    redirect_to menu_items_path
  end

  def move_to_bottom
    @menu_item.move_to_bottom
    @menu_item.save
    flash[:notice] = "Element moved to bottom."
    redirect_to menu_items_path
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
