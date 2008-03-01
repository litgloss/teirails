class ImagesController < ApplicationController
  include ActionController::Streaming

  before_filter :login_required, :except => [:show, :index, :stream]

  imageable_classes = ['Profile', 'ContentItem']

  def update
    @image = Image.find(params[:id])
    block_if_not_writable_by(current_user, @image)
    
    image_to_update = nil
    if !@image.parent.nil?
      image_to_update = @image.parent
    else
      image_to_update = @image
    end

    if image_to_update.update_attributes(params[:image])
      image_to_update.thumbnails.each do |t|
        t.update_attributes(params[:image])
      end

      flash[:notice] = 'Image was successfully updated.'
      redirect_to image_path
    else
      render :action => 'edit'
    end
  end

  def new
    @imageable_type = params[:imageable_type]
    @imageable_id = params[:imageable_id]

    @image = Image.new(:imageable_type => @imageable_type,
                       :imageable_id => @imageable_id)

    block_if_not_creatable_by(current_user, @image)
  end

  def stream
    if Image.find_by_id(params[:id])
      image = Image.find(params[:id])

      block_if_not_readable_by(current_user, image)

      content_type = image.content_type

      filename = image.public_filename

      send_file filename, :type => content_type, :disposition => 'inline'
    else
      # Stream "not found" image instead.
      filename = RAILS_ROOT + "/public/images/image_not_found.png"
      
      send_file filename, :type => 'image/png', :disposition => 'inline'
    end
  end

  def index
    @imageable_type = params[:imageable_type]
    @imageable_id = params[:imageable_id]

    @associated_object = 
      eval(@imageable_type.camelize).find(@imageable_id)

    block_if_not_readable_by(current_user, @associated_object)

    if @imageable_type.eql?("content_item")
      @images = ContentItem.find(@imageable_id).images
    else
      @images = Image.find(:all, :conditions => {
                             :parent_id => nil,
                             :imageable_type => @imageable_type,
                             :imageable_id => @imageable_id
                           })
    end
  end

  def edit
    @image = Image.find(params[:id])
    block_if_not_writable_by(current_user, @image)
  end

  def show
    @image = Image.find(params[:id])
    block_if_not_readable_by(current_user, @image)

    # If we aren't passed a parameter for "size",
    # display medium-sized image.

    if params[:size]
      size = params[:size]
    else
      size = "medium"
    end

    # Don't send back full-sized pictures, always
    # go with params[:size] or default.
    if @image.parent.nil?
      @image = Image.find(:first, :conditions => {
                            :parent_id => @image.id,
                            :thumbnail => size
                          })
    else
      @image = Image.find(:first, :conditions => {
                            :parent_id => @image.parent_id,
                            :thumbnail => size
                          })
    end
  end

  def create
    @image = Image.new(params[:image])
    block_if_not_creatable_by(current_user, @image)

    @image.creator = current_user

    if @image.save
      flash[:notice] = 'Image was successfully created.'
      redirect_to image_path(@image)
    else
      render :action => :new
    end
  end

  def destroy
    @image = Image.find(params[:id])
    block_if_not_writable_by(current_user, @image)

    imageable_type = @image.imageable_type
    imageable_id = @image.imageable_id
    associated_object = @image.get_associated_object

    p = nil

    if !@image.parent.nil?
      p = @image.parent
    else
      p = @image
    end

    if p.destroy
      flash[:notice] = 'Image deleted.'
    else
      flash[:error] = 'Error deleting image.'
    end

    case imageable_type
    when "content_item"
      redirect_to images_path(:imageable_type => "content_item", 
                              :imageable_id => imageable_id)
    when "litgloss"
      redirect_to images_path(:imageable_type => "litgloss", 
                              :imageable_id => imageable_id)

    when "profile"
      redirect_to user_profile_path(associated_object)
    end


  end
end
