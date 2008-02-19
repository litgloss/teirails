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

  # Prints index of content items passed to us
  # sorted by title.
  def by_title

    # Return content item array sorted alphabetically 
    # according to title.
    
    @content_items = get_content_items_with_filter(params[:filter])

    @content_items.sort! { |a, b| a.title.downcase <=> b.title.downcase }
  end


  # Returns a set of content items suitable for
  # display with this filter setting.  First parameter
  # to this method is the filter received.
  def get_content_items_with_filter(filter = nil, value = nil)
    content_items = nil

    case filter
    when "system"
      content_items = []
      ContentItem.find(:all).each do |c|
        if c.has_system_page
          content_items << c
        end
      end
      
    when "unpublished"
      content_items = ContentItem.find(:all, :conditions => {
                                          :published => false
                                        })
      
    else
      content_items = ContentItem.find(:all)

    end

    content_items
  end

  # Display unpublished content items.
  def unpublished
    @title = "Unpublished Content Items"
    @content_items = get_content_items_with_filter("unpublished")

    render :template => "content_items/index"
  end

  # Display system content items.
  def system
    @title = "System Content Items"
    @content_items = get_content_items_with_filter("system")

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
      
      if validate_tei(tei_data)
        @content_item.tei_data = tei_data
        @content_item.save!
      else
        flash[:error] = "TEI validation failed."
        redirect_to edit_content_item_path(@content_item)
        return
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


  # Prints index of content items passed to us
  # sorted by author.
  def by_author

    # Build a hash of unique authors, with keys being
    # content item objects.

    @content_items = {}

    ci_array = get_content_items_with_filter(params[:filter])
    
    ci_array.each do |ci|
      author = ci.authors[0] || "Unknown Author"
      if !@content_items.keys.include?(author)
        @content_items[author] = []
      end
      
      @content_items[author] << ci
    end

    @content_item_ary = @content_items.to_a.sort!
  end

  # Prints index of content items passed to us
  # sorted by language.
  def by_language

    # Build a hash of unique languages, with keys being
    # content item objects.

    @content_items = {}

    ci_array = get_content_items_with_filter(params[:filter])
    
    ci_array.each do |ci|
      language = ci.primary_language || "Unknown Language"
      if !@content_items.keys.include?(language)
        @content_items[language] = []
      end
      
      @content_items[language] << ci
    end

    @content_item_ary = @content_items.to_a.sort
  end


  protected
  
  # Sorting code from the ruby-talk mailing list:
  # http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/197213
  def sort_hash_by_key(hashtable)
    hashtable.keys.sort_by {|s| s.to_s}.map {|key| [key, hashtable[key]] }
  end

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
