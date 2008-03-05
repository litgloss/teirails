class ContentItemGroupLinksController < ApplicationController
  before_filter :login_required
  
  append_before_filter :find_content_item_group_link, :only => [:update, :destroy]
  append_before_filter :find_content_item_group

  def index
    block_if_not_writable_by(current_user, @content_item_group)

    # Populate this variable with possible content items to add to
    # this item.
    @unassociated_valid_content_items = ContentItem.find(:all,
                                                         :conditions => { 
                                                           :system => 
                                                           @content_item_group.system 
                                                         })

    @content_item_group.content_items.each do |ci|
      @unassociated_valid_content_items.delete(ci)
    end
  end

  # Associate this content item with the content item group.
  def create
    block_if_not_writable_by(current_user, @content_item_group)

    if !params[:content_item][:id] ||
        !ContentItem.find_by_id(params[:content_item][:id])
      flash[:error] = "Must select a valid content item."
      redirect_to content_item_group_links_path(@content_item_group)
    else
      @content_item = ContentItem.find(params[:content_item][:id])
      @content_item_group.content_items << @content_item
      if @content_item_group.save
        flash[:notice] = "Content item associated with group."
        redirect_to content_item_group_links_path(@content_item_group)
      else
        flash[:error] = "Failed to save content item with group."
        redirect_to content_item_group_links_path(@content_item_group)
      end
    end
  end

  def destroy
    block_if_not_writable_by(current_user, @content_item_group)

    if @content_item_group_link.destroy
      flash[:notice] = "Link to content item deleted from group."
      redirect_to content_item_group_links_path
    else
      flash[:error] = "Unable to destroy group link."
      render :index
    end
  end

  def update
    block_if_not_writable_by(current_user, @content_item_group)

    @content_item_group_link.group = @content_item_group

    if @content_item_group_link.save
      flash[:notice] = "New group set for content item."
    else
      flash[:error] = "Failed to save group for content item."
    end

    redirect_to content_item_path(@content_item)
  end

  protected
  def find_content_item_group
    @content_item_group = ContentItemGroup.find(params[:content_item_group_id])
  end

  def find_content_item_group_link
    @content_item_group_link = ContentItemGroupLink.find(params[:id])
  end

  private
  # Prohibit users less than editor for using any of these methods, restrict
  # action to administrators in individual methods where actions on system
  # groups is attempted.
  def authorized?
    current_user.can_act_as?("editor")
  end
end
