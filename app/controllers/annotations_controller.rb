class AnnotationsController < ApplicationController

  # Require HTTP auth for the create and update method,
  # since this comes from random annotea clients.
  before_filter :authenticate, :only => [ :create ]

  # Return list of annotations matching "target".
  def index

    if params[:w3c_annotates]
      @annotations = Annotation.find(:all, :conditions => {
                                       :annotates => params[:w3c_annotates]
                                     })
    else
      @annotations = Annotation.find(:all)
    end

    logger.info("\n\nWe got #{@annotations.size} annotations to show!!!\n\n")

    respond_to do |format|
      format.html

      # The address /annotations.xml should be used for
      # querying annotations with a response format
      # suitable for annotea clients.
      format.xml
    end
  end


  # Show an existing annotation (not yet sure how this would
  # work, as queries will use the index method.)
  def show
    @annotation = Annotation.find(params[:id])

    respond_to do |format|
      format.html
      format.xml
    end
  end


  # Returns the body of the annotation.
  def body
    @annotation = Annotation.find(params[:id])

    render :xml =>@annotation.body_to_xml, :content_type => @annotation.body_content_type
  end

  # Assume that the body of the message is not empty.  That
  # means that we automatically create two annotations:
  # one with an "external body" and another that is the body
  # of this submission.  The first one must contain in the body
  # the location of the real body.  phew.
  def create
    # logger.info(pp(params['RDF']))

    @annotation = nil

    # Get the last digit set from the replace_source if it exists as
    # the annotation ID we're working on.  This means that we're really
    # doing an update and not a create.
    if params[:replace_source]
      params[:replace_source].scan(/(\d+)$/)
      @annotation = Annotation.find($1)
    else
      @annotation = Annotation.new
    end

    @annotation.rdf_data = request.raw_post

    if @annotation.save
      @annotation.set_meta_fields
      render :xml => @annotation, :status => "201 Created", :location => formatted_annotation_path(@annotation, 'xml')
    end
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end


  private
  # Basic HTTP auth for users sending credentials through annotea
  # client.
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      !User.authenticate(username, password).nil?
    end
  end
end
