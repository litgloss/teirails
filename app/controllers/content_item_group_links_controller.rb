class ContentItemGroupLinksController < ApplicationController
  before_filter :login_required
  
  append_before_filter :find_content_item_group_link, :only => [:update]
  append_before_filter :find_content_item_group

  def index
    # Populate this variable with possible content items to add to this 
    @unassociated_valid_content_items = nil
    
    @unassociated_valid_content_items = ContentItem.find(:all, :conditions => { 
                                                           :system => @content_item_group.system
                                                         })

    @content_item_group.content_items.each do |ci|
      @unassociated_valid_content_items.remove(ci)
    end
  end

  def update
    gl = GroupLink.find(params[:id])
    
    gl.group = @content_item_group

    if gl.save
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
    @content_item = ContentItemGroupLink.find(params[:id])
  end

  private
  # XXX need more robust permission checking.
  def authorized?
    return true
  end
end
