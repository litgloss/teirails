class ContentsController < ApplicationController

  layout "layouts/application", :except => [:annotatable, :show]

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

    respond_to do |format|
      format.html
      format.xml { render :xml => @content.tei_data }
    end
  end

  def annotatable
    headers["Content-Type"] = "application/xhtml+xml"

    @content = Content.find(params[:id])
    render :xml => @content.tei_data
  end

  def update
    @content = Content.find(params[:id])

    if @content.update_attributes(params[:content])
      flash[:notice] = 'Content was successfully updated.'
      redirect_to content_path(@content)
    else
      render content
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
    if Content.find(params[:id]).destroy
      redirect_to contents_path
    end
  end

end
