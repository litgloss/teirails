class AudioFilesController < ApplicationController
  include ActionController::Streaming

  before_filter :login_required, :except => [:index, :show]

  # Streams this file as a sequence of bytes to the client.
  def stream
    audio_file = AudioFile.find(params[:id])
    block_if_not_readable_by(current_user, audio_file)

    block_if_not_readable_by(current_user, audio_file)

    content_type = audio_file.content_type

    filename = audio_file.public_filename

    send_file filename, :type => content_type, :disposition => 'inline'
  end

  def index


    if !params[:audible_type] ||
        !params[:audible_id] ||
        !AudioFile.audible_class_string?( params[:audible_type].camelize )
      flash[:error] = "Invalid input parameters, event logged."
      redirect_to search_path
    else
      @audio_files = AudioFile.find(:all, :conditions => { 
                                      :audible_type => params[:audible_type],
                                      :audible_id => params[:audible_id] }
                                    )
      
      @associated_object = eval(params[:audible_type].camelize).
        find(params[:audible_id])

      block_if_not_readable_by(current_user, @associated_object)
    end
  end

  def show
    @audio_file = AudioFile.find(params[:id])
    block_if_not_readable_by(current_user, @audio_file)


    @associated_object = @audio_file.heard_object
    logger.info("associated object id == #{@associated_object.id}")
  end
  
  def new
    @audio_file = AudioFile.new(:audible_type => 
                                params[:audible_type],
                                :audible_id => 
                                params[:audible_id])

    @associated_object = @audio_file.heard_object
    block_if_not_writable_by(current_user, @associated_object)

    # Filter out bad requests.
    if !params[:audible_type] ||
        !params[:audible_id] ||
        !AudioFile.audible_class_string?( params[:audible_type] )
      flash[:error] = "Type not audible or invalid input parameters."
      redirect_to search_path
    else
      # After calling AudioFile.audible_class_string, we can consider
      # the input to this method untainted.
      @audible_object = eval(params[:audible_type].camelize).new
      @title = 'Add a new audio file to this object'
      @audible_id = params[:audible_id]
    end
  end
  
  def create
    # XXX Permission filtering here.

    # Check to make sure that this is an audible object.
    if params[:audio_file][:audible_type] &&
        params[:audio_file][:audible_id] &&
        AudioFile.audible_class_string?( params[:audio_file][:audible_type] )
      
      @audio_file = AudioFile.new(params[:audio_file])
      block_if_not_writable_by(current_user, @audio_file)

      @audio_file.save
      flash[:notice] = 'Audio file was successfully saved.'
      redirect_to audio_file_path(@audio_file)
    else
      flash[:error] = 'Error creating audio file, event logged.'
      redirect_to search_path
    end
  end

  def edit
    @audio_file = AudioFile.find(params[:id])
    block_if_not_writable_by(current_user, @audio_file)
    @associated_object = @audio_file.heard_object
  end

  def update
    @audio_file = AudioFile.find(params[:id])
    block_if_not_writable_by(current_user, @audio_file)

    if @audio_file.update_attributes(params[:audio_file])
      flash[:notice] = 'Audio file was successfully updated.'
      redirect_to audio_files_path(@audio_file)
    else
      render edit_audio_file_path(@audio_file)
    end
  end

  def destroy
    @audio_file = AudioFile.find(params[:id])
    block_if_not_writable_by(current_user, @audio_file)

    audible_type = @audio_file.audible_type
    audible_id = @audio_file.audible_id
    associated_object = @audio_file.heard_object

    if @audio_file.destroy
      logger.info("OK, redirecting.")
      flash[:notice] = 'Audio file deleted.'
    else
      flash[:error] = 'Error deleting audio file.'
    end


    case audible_type
    when "content_item"
      redirect_to audio_files_path(:audible_type => "content_item", 
                                   :audible_id => audible_id)
    when "litgloss"
      redirect_to audio_files_path(:audible_type => "litgloss", 
                                   :audible_id => audible_id)
    end
  end
end
