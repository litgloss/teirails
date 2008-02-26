class ContentItemsController < ApplicationController
  layout "layouts/application", :except => [:annotatable, :show]

  before_filter :find_content_item, :only => [:edit, :show, 
                                              :annotatable, 
                                              :update]

  methods_ok_without_login = [ :index, :search, :show, 
                               :by_language, :by_author, :by_title ]

  append_before_filter :login_required, :except => methods_ok_without_login

  def search
    # If search term is empty, redirect back with error.
    if params[:term].empty?
      flash[:error] = "Search term empty."
      has_errors = true
    end

    # If there are invalid characters in term, send error.
    if !(params[:term] =~ /^[a-zA-Z0-9 ]+$/)
      flash[:error] = "Search string can only contain alphanumeric " +
        "characters and spaces, please try again."
      has_errors = true
    end

    if params[:term].length > 20
      flash[:error] = "Search term longer than 20 characters."
      has_errors = true
    end

    # Check that we have at least one search criteria.
    unless has_search_part?
      flash[:error] = "Search failed: You need to check at least one box below."
      has_errors = true
    end

    if has_errors
      redirect_to search_path
      return
    end


    @term = params[:term]
    @content_items = get_content_items_with_filter('search')
  end
  
  # Default method for displaying all published content items
  # 
  def index
    cis = ContentItem.find(:all, :conditions => {
                             :published => true
                           })
    
    @content_items = []

    cis.each do |c|
      if !c.has_system_page
        @content_items << c
      end
    end

    @content_items = 
      ContentItem.filter_content_item_ary_by_user_level(@content_items, 
                                                        current_user)

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
  def get_content_items_with_filter(filter = nil, search_term = nil,
                                    search_symbols = nil)
    content_items = nil

    case filter
    when "system"
      content_items = []

      if current_user.can_act_as?("administrator")
        ContentItem.find(:all).each do |c|
          if c.has_system_page
            content_items << c
          end
        end
      end
      
      content_items = ContentItem.remove_cloned_content_items(content_items)

    when "unpublished"
      if current_user.can_act_as?("contributor")
        content_items = ContentItem.find(:all, :conditions => {
                                           :published => false
                                         })
      end

      content_items = ContentItem.remove_cloned_content_items(content_items)
      content_items = ContentItem.remove_system_content_items(content_items)

    when "search"
      # Return list of content items that user is allowed to 
      # view in all categories that we received in the search_symbols
      # ary.
      content_items = ContentItem.find_matching(params[:term],
                                                get_search_parts)

      content_items = ContentItem.remove_cloned_content_items(content_items)
      content_items = ContentItem.remove_system_content_items(content_items)
    else
      content_items = ContentItem.find(:all, :conditions => 
                                       { :published => true } )

      content_items = ContentItem.remove_cloned_content_items(content_items)
      content_items = ContentItem.remove_system_content_items(content_items)
    end

    ContentItem.filter_content_item_ary_by_user_level(content_items, 
                                                      current_user)
  end

  # Display unpublished content items.
  def unpublished
    if !current_user.can_act_as?("contributor")
      redirect_to_block(current_user, nil)
    end

    @title = "Unpublished Content Items"
    @content_items = get_content_items_with_filter("unpublished")

    render :template => "content_items/index"
  end

  # Display system content items.
  def system
    if !current_user.can_act_as?("administrator")
      redirect_to_block(current_user, nil)
      return
    end

    @title = "System Content Items"
    @content_items = get_content_items_with_filter("system")

    render :template => "content_items/index"
  end

  def new
    if !current_user.can_act_as?("editor")
      redirect_to_block(current_user, nil)
      return
    end

    @content_item = ContentItem.new
  end

  def edit
    block_if_not_writable_by(current_user, @content_item)
  end

  def show
    if @content_item.readable_by?(current_user)
      respond_to do |format|
        format.html {
          tei_data = @content_item.tei_data

          if params[:term_to_annotate]
            tei_data = 
              @content_item.
              insert_temporary_ref_tags_for_string_match(@content_item.doc, 
                                                         params[:term_to_annotate])

            if params[:term_to_annotate] && 
                !tei_data.eql?(@content_item.tei_data)
              @message = "Annotation markup mode: Phrases in the document " + 
                "matching the term that you specified have been highlighted " + 
                "in red.  Click on the term that you want to mark to add an " + 
                "annotation."
            end
          end
          
          rendered_text = @content_item.tei_data_to_xhtml(tei_data)

          render :inline => rendered_text
        }

        format.xml { render :xml => @content_item.tei_data }
      end
    else
      flash[:error] = "You do not have permission to access this resource."
      redirect_to login_path
    end
  end

  def annotatable
    headers["Content-Type"] = "application/xhtml+xml"

    render :xml => @content_item.tei_data
  end

  def update
    block_if_not_writable_by(current_user, @content_item)

    # Save tei_data if it was provided.
    if params[:content_item][:tei_data].class == 
        ActionController::UploadedStringIO.new.class
      @content_item.tei_data = params[:content_item][:tei_data].read
    end

    @content_item = set_content_item_properties(@content_item)
    
    if @content_item.save
      flash[:notice] = "New content item data saved."
      redirect_to content_item_path
    else
      render :action => :edit
    end
  end

  def create
    if !current_user.can_act_as?("editor")
      redirect_to_block(current_user, nil)
      return
    end

    @content_item = ContentItem.new

    @content_item.tei_data = params[:content_item][:tei_data].read
    @content_item = set_content_item_properties(@content_item)

    if @content_item.save
      flash[:notice] = "New content item data saved."
      redirect_to content_item_path(@content_item)
    else
      render :action => :new
    end
  end

  def destroy
    @content_item = ContentItem.find(params[:id])
    block_if_not_writable_by(current_user, @content_item)

    clone = ContentItem.find(params[:id]).private_clone?

    if ContentItem.find(params[:id]).destroy
      if clone
        flash[:notice] = "Cloned content item deleted."
        redirect_to user_profile_path(current_user)
      else
        flash[:notice] = "Content item deleted."
        redirect_to content_items_path
      end

    else
      flash[:error] = "Failed to delete content item."
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


  # Sets properties for content item, including system page
  # and published.
  def set_content_item_properties(content_item)
    content_item.creator = current_user

    # These options don't make sense for private clones!
    if !content_item.private_clone?
      
      if current_user.can_act_as?("editor")
        content_item.published = params[:content_item][:published]
        content_item.protected = params[:content_item][:protected]
      end
      
      if (logged_in? && current_user.can_act_as?("administrator"))
        content_item.
          set_system_page_value(params[:content_item][:has_system_page])
      end
    end

    return content_item
  end

  def get_search_parts
    possible_parts = [:titles, :authors, :bodies]
    parts_to_search = []

    possible_parts.each do |s|
      if params.include?(s)
        parts_to_search << s
      end
    end

    parts_to_search
  end

  def has_search_part?
    search_parts = [:titles, :authors, :bodies]
    
    has_sp = false
    search_parts.each do |s|
      if params.include?(s)
        search_parts = true
      end
    end
    
    search_parts
  end

end
