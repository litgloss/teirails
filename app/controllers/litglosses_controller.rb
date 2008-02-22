class LitglossesController < ApplicationController
  before_filter :get_content_item

  append_before_filter :get_litgloss, :only => [:edit, :show]

  def edit
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

    @content_item.tei_data = 
      @content_item.create_glossed_link(@content_item.doc, @litgloss).to_s

    @content_item.save
    
    flash[:notice] = "Litgloss saved."
    redirect_to content_item_path(@content_item)
  end

  def show
    
  end

  protected
  def get_content_item
    @content_item = ContentItem.find(params[:content_item_id])
  end

  def get_litgloss
    @litgloss = Litgloss.find(params[:id])
  end
end
