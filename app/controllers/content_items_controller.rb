class ContentItemsController < ApplicationController
  include TeiHelper

  layout "layouts/application", :except => [:annotatable, :show]

  before_filter :find_content_item, :only => [:edit, :show, :annotatable, 
                                              :update]


  # Default method for displaying all published content items
  # 
  def index
    cis = ContentItem.find(:all, :conditions => {
                            :published => true
                          })

    @content_items = []
    cis.each do |c|
      @content_items << c unless c.has_system_page
    end

    @title = "Public Content Items"
  end

  # Display unpublished content items.
  def unpublished
    @title = "Unpublished Content Items"
    @content_items = ContentItem.find(:all, :conditions => {
                            :published => false
                          })
    
    render :template => "content_items/index"
  end


  # Display system content items.
  def system
    @title = "System Content Items"

    @content_items = []
    ContentItem.find(:all).each do |c|
      if c.has_system_page
        @content_items << c
      end
    end

    render :template => "content_items/index"
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
    # Save tei_data if it was provided.
    if params[:content_item][:tei_data].class == 
        ActionController::UploadedStringIO.new.class

      tei_data = params[:content_item][:tei_data].read
      
      logger.info("got tei_data before val call:\n#{tei_data}")

      if validate_tei(tei_data)
        @content_item.tei_data = tei_data
        @content_item.save!
      else
        redirect_to edit_content_item_path(@content_item)    
      end
    end
    
    set_content_item_properties

    redirect_to content_item_path(@content_item)
  end

  def create
    @content_item = ContentItem.new

    tei_data = params[:content_item][:tei_data].read

    if !validate_tei(tei_data)
      redirect_to new_content_item_path
    else
      @content_item.tei_data = tei_data
      if @content_item.save
        set_content_item_properties
        flash[:notice] = 'Content item was successfully created.'
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

    logger.info("\n\nGOT string to val: #{tei_string}\n\n")

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

  # Sets properties for content item, including system page
  # and published.
  def set_content_item_properties
    @content_item.published = params[:content_item][:published]

    begin
      @content_item.
        set_system_page_value(params[:content_item][:has_system_page])
    rescue Exception => e
      flash[:error] = "Exception: #{e}"
      redirect_to edit_content_item_path(@content_item)
      return
    end
    
    @content_item.save!
  end
end
