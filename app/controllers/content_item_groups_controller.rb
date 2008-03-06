class ContentItemGroupsController < ApplicationController
  before_filter :find_content_item_group, :only => [:edit, :show, :update, :destroy,
                                                    :move_higher, :move_lower,
                                                    :move_to_top, :move_to_bottom]

  append_before_filter :login_required, :except => :show

  def index
    if params[:type] == "system" &&
        current_user.can_act_as?("administrator")
      @content_item_groups = ContentItemGroup.find(:all, :order => :position, 
                                                   :conditions => {
                                                     :system => true
                                                   })
    else
      @content_item_groups = ContentItemGroup.find(:all, :order => :position,
                                                   :conditions => {
                                                     :system => false
                                                   })
    end

  end

  def new
    @content_item_group = ContentItemGroup.new
  end

  def edit
    block_if_not_writable_by(current_user, @content_item_group)
  end

  def show
    # If we have one or more elements in this content item group, show the item in the first
    # position.  Otherwise, just render the index page.
    if !@content_item_group.content_items.empty?
      ci = @content_item_group.content_items.find(:first, :order => :position)
      redirect_to content_item_path(ci, :group => @content_item_group.id)
    end
  end

  # Moves this element in the list to a higher position.
  def move_higher
    block_if_not_writable_by(current_user, @content_item_group)

    @content_item_group.move_higher
    @content_item_group.save
    flash[:notice] = "Element moved higher."
    redirect_to content_item_groups_path(get_system_hash_for(@content_item_group))
  end

  # Moves this element in the list to a lower position.
  def move_lower
    block_if_not_writable_by(current_user, @content_item_group)

    @content_item_group.move_lower
    @content_item_group.save
    flash[:notice] = "Element moved lower."
    redirect_to content_item_groups_path(get_system_hash_for(@content_item_group))
  end

  def move_to_top
    block_if_not_writable_by(current_user, @content_item_group)

    @content_item_group.move_to_top
    @content_item_group.save
    flash[:notice] = "Element moved to top."
    redirect_to content_item_groups_path(get_system_hash_for(@content_item_group))
  end

  def move_to_bottom
    block_if_not_writable_by(current_user, @content_item)

    @content_item_group.move_to_bottom
    @content_item_group.save
    flash[:notice] = "Element moved to bottom."
    redirect_to content_item_groups_path(get_system_hash_for(@content_item_group))
  end

  def destroy
    block_if_not_writable_by(current_user, @content_item_group)

    if @content_item_group.destroy
      flash[:notice] = "Content item group deleted."
      redirect_to content_item_groups_path(get_system_hash_for(@content_item_group))
    else
      flash[:error] = "Unable to destroy content item group."
      redirect_to content_item_groups_path(get_system_hash_for(@content_item_group))
    end
  end

  def update
    if @content_item_group.update_attributes(params[:content_item_group])
      flash[:notice] = 'Group details were successfully updated.'
      redirect_to content_item_group_path(@content_item_group)
    else
      flash[:error] = 'Failed to update group properties.'
      redirect_to content_item_group_path(@content_item_group)
    end
  end

  def create
    @content_item_group = ContentItemGroup.new(params[:content_item_group])
    @content_item_group.save!

    flash[:notice] = "New content_item_group created with name #{@content_item_group.name}"
    redirect_to content_item_groups_path(get_system_hash_for(@content_item_group))
  end

  protected
  def find_content_item_group
    @content_item_group = ContentItemGroup.find(params[:id])
  end

  def get_system_hash_for(content_item_group)
    if content_item_group.system?
      { :type => "system" }
    else
      { }
    end
  end


  private 
  # Since these methods are mostly for managing groups, block access if 
  # user is not able to at least act as an editor.
  def authorized?
    current_user.can_act_as?("editor")
  end
end
