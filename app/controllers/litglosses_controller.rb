class LitglossesController < ApplicationController
  before_filter :get_content_item

  append_before_filter :get_litgloss, :only => [:edit, :show, :update, :destroy]

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
