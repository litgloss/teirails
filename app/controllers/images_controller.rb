class ImagesController < ApplicationController
  include ActionController::Streaming

  before_filter :login_required, :only => [ :new, :create, :edit,
                                            :update, :destroy ]
  imageable_classes = ['Profile', 'Content']

  def update
    @image = Image.find(params[:id])

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

    @image = Image.new
  end

  def stream
    # Put access filters here to make sure that user
    # is able to view this image. XXX
    image = Image.find(params[:id])
    content_type = image.content_type

    filename = image.public_filename

    send_file filename, :type => content_type, :disposition => 'inline'
  end

  def index
    @imageable_type = params[:imageable_type]
    @imageable_id = params[:imageable_id]

    @images = Image.find(:all, :conditions => {
                           :parent_id => nil,
                           :imageable_type => @imageable_type,
                           :imageable_id => @imageable_id
                         })
  end

  def edit
    @image = Image.find(params[:id])
  end

  def show
    @image = Image.find(params[:id])

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

    @image.creator = current_user

    if @image.save
      flash[:notice] = 'Image was successfully created.'
      redirect_to image_path(@image)
    else
      render new_image_path
    end
  end

  def destroy
    @image = Image.find(params[:id])

    p = nil

    if !@image.parent.nil?
      p = @image.parent
    else
      p = @image
    end

    if p.destroy
      flash[:notice] = 'Image deleted.'
      redirect_to images_path
    else
      flash[:error] = 'Error deleting image.'
    end
  end
end
