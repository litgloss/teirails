class VersionsController < ApplicationController
  before_filter :get_content_item

  def index
    @versions = @content_item.versions
  end

  def show
    # Get the requested version of this content item.
    @content_item.revert_to(params[:id])

    respond_to do |format|
      format.html {
        render :inline => @content_item.tei_data_to_xhtml
      }
      format.xml { render :xml => @content_item.tei_data }
    end
  end

  # Reverts a content item to a previous version.
  def revert_to
    target_revision = params[:id]
    
    if @content_item.revert_to!(target_revision)
      flash[:notice] = "Content item reverted to previous version."
      redirect_to content_item_versions_path(@content_item)
    else
      flash[:error] = "Failed to revert content item to previous version."
      redirect_to content_item_versions_path(@content_item)
    end
  end
  
  protected
  def get_content_item
    @content_item = ContentItem.find(params[:content_item_id])
  end
end
