class ContentItemsController < ApplicationController
  include TeiHelper

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

  # Updates the tei_data property of this model, as long
  # as the string given to us conforms to the TEI DTD.
  def update
    tei_data = params[:content_item][:tei_data].read

    if !validate_tei(tei_data)
      redirect_to edit_content_item_path(@content_item)    
    else
      @content_item.tei_data = tei_data
      if @content_item.save
        flash[:notice] = 'Content item was successfully updated.'
        redirect_to content_item_path(@content_item)
      else
        flash[:notice] = "Failed to save new tei data."
        redirect_to edit_content_item_path(@content_item)            
      end
    end
  end

  def create
    @content_item = ContentItem.new

    tei_data = params[:content_item][:tei_data].read

    if !validate_tei(tei_data)
      redirect_to new_content_item_path
    else
      @content_item.tei_data = tei_data
      if @content_item.save
        flash[:notice] = 'Content item was successfully updated.'
        redirect_to content_item_path(@content_item)
      else
        flash[:notice] = "Failed to save new tei data."
        redirect_to new_content_item_path 
      end
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

  # Checks whether a TEI string is valid XML and whether
  # or not it is valid according to a TEI DTD.  If document
  # has problems, set the flash[:error] variable to a useful
  # message and return false.  Else, return true.
  def validate_tei(tei_string)
    has_errors = false

    begin
      res = validate_tei_document(tei_string)
    rescue XML::Parser::ParseError
      flash[:error] = "Document does not contain valid XML." + 
        "  Please correct and try uploading again."


      has_errors = true
    rescue DTDValidationFailedError
      flash[:error] = "Document failed to validate against "  +
        "a schema for TEI Lite.  Please fix and try uploading again."

      has_errors = true
    end

    return !has_errors
  end
end
