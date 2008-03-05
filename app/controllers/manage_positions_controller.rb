# Allows user to re-arrange order of pages under a content item group.
class ManagePositionsController < ApplicationController
  append_before_filter :login_required

  before_filter :get_content_item_group

  append_before_filter :get_system_page, :only => 
    [
     :move_higher,
     :move_lower,
     :move_to_top,
     :move_to_bottom
    ]

  def index
    @content_items = @content_item_group.content_items
  end

  # Moves this element in the list to a higher position.
  def move_higher
    @content_item.move_higher
    @content_item.save
    flash[:notice] = "Element moved higher."
    redirect_to content_item_group_manage_content_items_path(@content_item.content_item_group)
  end

  # Moves this element in the list to a lower position.
  def move_lower
    @content_item.move_lower
    @content_item.save
    flash[:notice] = "Element moved lower."
    redirect_to content_item_group_manage_content_items_path(@content_item.content_item_group)
  end

  def move_to_top
    @content_item.move_to_top
    @content_item.save
    flash[:notice] = "Element moved to top."
    redirect_to content_item_group_manage_content_items_path(@content_item.content_item_group)
  end

  def move_to_bottom
    @content_item.move_to_bottom
    @content_item.save
    flash[:notice] = "Element moved to bottom."
    redirect_to content_item_group_manage_content_items_path(@content_item.content_item_group)
  end


  protected

  def get_content_item
    @content_item = ContentItem.find(params[:id])
  end

  def get_content_item_group
    @content_item_group = ContentItemGroup.find(params[:content_item_group_id])
  end

  private
  def authorized?
    current_user.can_act_as?("administrator")
  end
end
