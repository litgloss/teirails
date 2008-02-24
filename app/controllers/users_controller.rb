class UsersController < ApplicationController
  # Protect these actions behind an admin login

  protected_methods = [ :suspend, :unsuspend, 
                       :destroy, :purge, :update ]

  before_filter :admin_required, :only => protected_methods
  append_before_filter :login_required, :except => [:new, :create, :activate]
  
  append_before_filter :find_user, :only => [:suspend, :unsuspend, :destroy, 
                                             :purge, :edit]
  

  def index
    @users = User.find(:all)
  end

  def edit
  end

  # Commits changes to user model.  Currently only works 
  # for user role management.
  def update
    @user = User.find(params[:id])
    
    if @user.role != UserRole.find(params[:user][:role_id])
      @user.role = UserRole.find(params[:user][:role_id])
      @user.save
    end

    flash[:notice] = 'User data updated.'
    redirect_to edit_user_path(@user)
  end


  # render new.rhtml
  def new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.save!
    
    # Don't log in user who just signed up, since activation is
    # required.  
    # self.current_user = @user

    redirect_back_or_default('/')
    flash[:notice] = "Thanks for signing up!  Please check your email account " +
      "in a few minutes for an activation message."

  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def activate
    self.current_user = params[:activation_code].blank? ? :false : User.find_by_activation_code(params[:activation_code])

    if logged_in? && !current_user.active?
      current_user.activate!
      flash[:notice] = "Signup complete!"
    else
      flash[:error] = "Sorry, we couldn't activate your account."
    end

    redirect_back_or_default('/')
  end

  def suspend
    @user.suspend! 
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend! 
    redirect_to users_path
  end

  def destroy
    @user.delete!
    redirect_to users_path
  end

  def purge
    @user.destroy
    redirect_to users_path
  end

protected
  def find_user
    @user = User.find(params[:id])
  end

  def admin_required
    if !current_user.can_act_as?("administrator")
      redirect_to_block(current_user, nil)
      return
    end
  end

end
