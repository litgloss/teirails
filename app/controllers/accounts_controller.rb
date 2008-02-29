# AccountsController: Allow users to change their passwords.  This
# controller is constructed so that only the currently logged-in user
# can change her password.
class AccountsController < ApplicationController
  before_filter :find_user
  append_before_filter :login_required

  # Edit user password.
  def edit
  end

  # Set user password.
  def update
    if params[:password] == params[:password_confirmation]
      @user.password = params[:password]
      @user.password_confirmation = params[:password_confirmation]

      if @user.save
        flash[:notice] = "Password updated.  Next time you visit the system you may " + 
          " log in with your new credentials."
        redirect_to user_profile_path
      else
        flash[:error] = "Unable to save user record."
        redirect_to edit_user_account_path
      end
      
    else
      flash[:error] = "Password and password confirmation didn't match.  Please try again."
      redirect_to edit_user_account_path
    end
  end


  protected
  def find_user
    @user = User.find(params[:user_id])
  end

  private 
  def authorized?
    @user == current_user
  end
end
