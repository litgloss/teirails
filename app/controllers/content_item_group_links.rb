# Allows users to associate a system page with a menu item.  Only
# administrators should have access to these methods.
class GroupLinksController < ApplicationController
  before_filter :login_required
  
  append_before_filter :find_content_item_group, :only => [:update]
  append_before_filter :find_content_item

  def index
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
    @content_item_group = ContentItemGroup.find(params[:id])
  end

  def find_content_item
    @content_item = ContentItem.find(params[:content_item_id])
  end

  private
  def authorized?
    current_user.can_act_as?("administrator")
  end
end
