# Manages clone of a content item.
class ClonesController < ApplicationController
  before_filter :get_content_item

  append_before_filter :get_clone, :only => [:show, :update]

  append_before_filter :login_required

  # Does a "pull" from one content item to another.
  def update
    case params[:from]
    when "parent"
      @clone.pull!(@content_item)

      flash[:notice] = "Pulled TEI data from master."
    when "clone"
      @content_item.pull!(@clone)

      flash[:notice] = "Pulled TEI data from clone."
    else
      flash[:error] = "Invalid value for content origin."
    end

    redirect_to content_item_clone_path(@content_item, @clone)
  end

  # Shows properties of this clone, and relationship
  # to parent content item.
  def show
    parent_prophash = {}

    parent_prophash["Parent Title"] = @content_item.title
    parent_prophash["Parent ID"] = @content_item.id
    parent_prophash["Parent Created"] = @content_item.created_at
    parent_prophash["Parent Updated"] = @content_item.updated_at
    parent_prophash["Parent Creator"] = @content_item.creator.full_name


    clone_prophash = {}

    clone_prophash["Clone Title"] = @clone.title
    clone_prophash["Clone ID"] = @clone.id
    clone_prophash["Clone Created"] = @clone.created_at
    clone_prophash["Clone Updated"] = @clone.updated_at
    clone_prophash["Clone Creator"] = @clone.creator.full_name

    @clone_propset = clone_prophash.to_a.sort
    @parent_propset = parent_prophash.to_a.sort
  end

  # Shows a list of all clones of the selected ContentItem.
  def index
    @clones = @content_item.private_clones
  end

  # Shows message before creating clone, and form
  # to commit this action.
  def new

  end

  # Creates a clone of this document.
  def create
    @clone = @content_item.private_clone(current_user)

    if !@clone.nil?
      flash[:notice] = "Clone created."
      redirect_to content_item_clone_path(@content_item, @clone)
    else
      flash[:error] = "Unable to create clone for this object."
      redirect_to content_item_path(@content_item)
    end
  end

  def destroy
    
  end

  protected
  def get_content_item
    @content_item = ContentItem.find(params[:content_item_id])
  end

  def get_clone
    @clone = ContentItem.find(params[:id])
  end
end
