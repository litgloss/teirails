class ContentItemsController < ApplicationController

  layout "layouts/application", :except => [:annotatable, :show]

  before_filter :find_content_item, :only => [:edit, :show, :annotatable, 
                                              :update]


  def index
    @content_items = ContentItem.find(:all)
  end

  def new
    @content_item = ContentItem.new
  end

  def edit
  end

  def show

    respond_to do |format|
      format.html {
        render :inline => @content_item.tei_data_to_xhtml
      }
      format.xml { render :xml => @content_item.tei_data }
    end
  end

  def annotatable
    headers["Content-Type"] = "application/xhtml+xml"

    render :xml => @content_item.tei_data
  end

  def update
    if @content_item.update_attributes(params[:content_item])
      flash[:notice] = 'Content item was successfully updated.'
      redirect_to content_path(@content_item)
    else
      render content_item
    end
  end

  def create
    @content_item = ContentItem.new(params[:content_item])

    if @content_item.save
      flash[:notice] = 'Content was successfully created.'
      redirect_to content_path(@content_item)
    else
      render :action => :new
    end

  end

  def destroy
    if ContentItem.find(params[:id]).destroy
      redirect_to content_items_path
    end
  end


  protected
  def find_content_item
    @content_item = ContentItem.find(params[:id])    
  end

end
