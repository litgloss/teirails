class ProfilesController < ApplicationController
  before_filter :get_user

  def show
    @profile = @user.profile

    @cloned_content_items = @user.cloned_content_items

    if !@profile.image.nil?
      @image = @user.profile.image.thumbnails.find_by_thumbnail("small")
    end
  end

  def edit
    @profile = @user.profile
  end

  def update
    @profile = @user.profile

    if @profile.update_attributes(params[:profile])
      flash[:notice] = 'Profile details were successfully updated.'
      redirect_to user_profile_path(@user)
    else
      render user_edit_profile
    end
  end

  protected
  def get_user
    @user = User.find(params[:user_id])
  end
end
