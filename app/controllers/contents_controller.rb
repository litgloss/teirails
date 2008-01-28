class ContentsController < ApplicationController
  
  layout "layouts/application", :except => :xhtml_teidata

  def index
    @contents = Content.find(:all)
  end

  def new
    @content = Content.new
  end

  def edit
    @content = Content.find(params[:id])
  end

  def show
    @content = Content.find(params[:id])

    logger.info("hey, junk.")
    respond_to do |format|
      format.html
      format.xml { render :xml => @content.teidata }
    end
  end

  def xhtml_teidata
    @content = Content.find(params[:id])

    @text = @content.get_xhtml_teidata
  end

  def update
    @content = Content.find(params[:id])

    if @content.update_attributes(params[:content])
      flash[:notice] = 'Content was successfully updated.'
      redirect_to content_path(@content)
    else
      render wedding_content
    end

  end

  def create
    @content = Content.new(params[:content])
    
    if @content.save
      flash[:notice] = 'Content was successfully created.'
      redirect_to content_path(@content)
    else
      render :action => :new
    end

  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

end
