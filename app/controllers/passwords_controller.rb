class PasswordsController < ApplicationController
  # Enter email address to recover password 
  def new
  end
  
  # Forgot password action
  def create    
    return unless request.post?

    if @user = User.find_for_forget(params[:email])
      @user.forgot_password
      @user.save      
      flash[:notice] = "A password reset link has been sent to your email address."
      redirect_to login_path
    else
      flash[:error] = "Could not find a user with that email address."
      redirect_to new_password_path
    end  
  end
  
  # Action triggered by clicking on the /reset_password/:id link
  # recieved via email.  If code is correct, show form to reset
  # password.  Otherwise, redirect to new user page.
  def edit
    if params[:id].nil?
      render :action => 'new'
      return
    end
    @user = User.find_by_password_reset_code(params[:id]) if params[:id]
    raise if @user.nil?
  rescue
    logger.error("Invalid Reset Code entered.")

    flash[:error] = "Sorry - That is an invalid password reset code. Please check your code and try again. " + 
      "(Perhaps your email client inserted a carriage return?)"

    redirect_to new_user_path
  end
  
  def update
    if params[:id].nil?
      flash[:error] = "Must supply reset code to update password."
      redirect_to login_path
      return
    end

    if params[:password].blank?
      flash[:notice] = "Password field cannot be blank."
      render :action => 'edit', :id => params[:id]
      return
    end

    @user = User.find_by_password_reset_code(params[:id]) if params[:id]

    if @user.nil?
      flash[:error] = "Invalid reset code."
      redirect_to login_path
      return
    end

    if (params[:password] == params[:password_confirmation])

      @user.password = params[:password]
      @user.password_confirmation = params[:password_confirmation]

      @user.password_reset_code = nil

      @user.save

      flash[:notice] = "Your password has been reset, you may now log " + 
        "in using your new credentials."
      redirect_to content_items_path
    else
      flash[:error] = "Passwords don't match, please try again."
      redirect_to '/'
    end
  end
  
end


