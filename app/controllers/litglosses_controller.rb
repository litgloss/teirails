class LitglossesController < ApplicationController
  before_filter :get_content_item

  append_before_filter :get_litgloss, :only => [:edit, :show, :update, :destroy]
  append_before_filter :login_required, :except => [:show, :index]

  def edit
    
  end
  
  def update
    if @litgloss.update_attributes(params[:litgloss])
      flash[:notice] = 'Litgloss details were successfully updated.'
      redirect_to content_item_litgloss_path
    else
      flash[:error] = 'Failed to update litgloss properties.'
      redirect_to content_item_litgloss_path
    end
  end

  def new
    # For some reason, older REXML instances ignore the raw flag
    # on elements and convert them.  For that reason we might have 
    # botched input parameters at this point.  Figure out if this
    # is the case and fix it before we create the form for our new
    # litgloss.
    
    if params['amp;count'.to_sym]
      params[:count] = params['amp;count'.to_sym]
    end

    @litgloss = Litgloss.new
  end

  def index
    @litglosses = @content_item.litglosses
  end

  def create
    @litgloss = Litgloss.new(params[:litgloss])
    @litgloss.creator = current_user
    @litgloss.content_item = @content_item

    @litgloss.save

    tei_data = 
      @content_item.create_glossed_link(@content_item.doc, @litgloss).to_s

    if validate_tei(tei_data)
      @content_item.tei_data = tei_data
      flash[:notice] = "Litgloss saved."
      @content_item.save
      redirect_to content_item_path(@content_item)
    else
      redirect_to content_item_path(@content_item)
    end
  end

  def show
    @audio_files = @litgloss.audio_files
    @images = @litgloss.images.find(:all, :conditions => {
                                      :parent_id => nil
                                    })
  end


  def destroy
    # Get rid of tags in document.    
    @content_item.delete_litgloss!(@litgloss)

    if @litgloss.destroy
      flash[:notice] = "Litgloss deleted."
    else
      flash[:error] = "Unable to delete litgloss."
    end
    
    redirect_to content_item_path(@content_item)
  end

  protected
  def get_content_item
    @content_item = ContentItem.find(params[:content_item_id])
  end

  def get_litgloss
    @litgloss = Litgloss.find(params[:id])
  end
end
