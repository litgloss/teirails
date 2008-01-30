require 'pp'

# Annotea protocol:
# http://www.w3.org/2002/12/AnnoteaProtocol-20021219
class AnnotationsController < ApplicationController
  # requires_authentication :using => :authenticate

  # Return list of annotations matching "target".
  def index
    if params[:w3c_annotates]
      @annotations = Annotation.find(:all, :conditions => {
                                       :annotates => params[:w3c_annotates]
                                     })
    else
      @annotations = Annotation.find(:all)
    end

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

  # Not sure if update will be useful, we may just have
  # to parse parameters from the regular post request to
  # see if it has a previous url.
  def update

  end

  # Returns the body of the annotation.
  def body
    respond_to do |format|
      format.html
      format.xml
    end
  end

  # Assume that the body of the message is not empty.  That 
  # means that we automatically create two annotations:
  # one with an "external body" and another that is the body
  # of this submission.  The first one must contain in the body
  # the location of the real body.  phew.
  def create
    logger.info(pp(params['RDF']))
    
    external_body_rec = Annotation.new

    external_body_rec.body = params['RDF']['Description']['body']['Message']['Body']['html']['body']

    rec.creator = params['RDF']['Description']['creator']
    rec.language = params['RDF']['Description']['language']
    rec.title = params['RDF']['Description']['body']['Message']['Body']['html']['head']['title']

    rec.date = params['RDF']['Description']['date']
    rec.created = params['RDF']['Description']['created']
    rec.annotates = params['RDF']['Description']['annotates']['r:resource']
    rec.context = params['RDF']['Description']['context']
 
    body_rec = Annotation.new

    if external_body_rec.save && body_rec.save
      @annotation = rec
      render :xml => rec, :status => "201 Created", :location => formatted_annotation_path(rec, 'xml')
    end
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  
  private
  def authenticate(username, password)
    return username == 'justin' && password == 'test'
  end
end
