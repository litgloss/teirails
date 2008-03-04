class ContentItemGroupsController < ApplicationController
  before_filter :find_group, :only => [:edit, :show, :update, :destroy,
                                       :move_higher, :move_lower,
                                       :move_to_top, :move_to_bottom]

  append_before_filter :login_required, :except => [:show]

  def index
    @content_item_groups = ContentItemGroup.find(:all, :order => :position)
  end

  def new
    @content_item_group = ContentItemGroup.new
  end

  def show
    if @content_item_group.content_items.find(:all, :conditions => { 
                                   :published => true 
                                 }).size > 0
      redirect_to content_item_path(@content_item_group.
                                    content_items.find(:first,
                                                       :conditions => {
                                                         :published => true
                                                       }))
      return
    end
  end

  # Moves this element in the list to a higher position.
  def move_higher
    @content_item_group.move_higher
    @content_item_group.save
    flash[:notice] = "Element moved higher."
    redirect_to groups_path
  end

  # Moves this element in the list to a lower position.
  def move_lower
    @content_item_group.move_lower
    @content_item_group.save
    flash[:notice] = "Element moved lower."
    redirect_to groups_path
  end

  def move_to_top
    @content_item_group.move_to_top
    @content_item_group.save
    flash[:notice] = "Element moved to top."
    redirect_to groups_path
  end

  def move_to_bottom
    @content_item_group.move_to_bottom
    @content_item_group.save
    flash[:notice] = "Element moved to bottom."
    redirect_to groups_path
  end

  def destroy
    if @content_item_group.destroy
      flash[:notice] = "group deleted."
      redirect_to groups_path
    else
      flash[:error] = "Unable to destroy group."
      redirect_to groups_path
    end
  end

  def update
    if @content_item_group.update_attributes(params[:content_item_group])
      flash[:notice] = 'Group details were successfully updated.'
      redirect_to group_path(@content_item_group)
    else
      flash[:error] = 'Failed to update group properties.'
      redirect_to content_item_group_path(@content_item_group)
    end
  end

  def create
    @content_item_group = ContentItemGroup.new(params[:content_item_group])
    @content_item_group.save!

    flash[:notice] = "New content_item_group created with name #{@content_item_group.name}"
    redirect_to content_item_groups_path
  end

  protected
  def find_content_item_group
    @content_item_group = ContentItemGroup.find(params[:id])
  end

end
