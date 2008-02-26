class InstallController < ApplicationController
  append_before_filter :first_time_only

  def show
    redirect_to new_install_path
  end

  def new
    
  end

  # Creates a user with administrative privileges.
  def create
    cookies.delete :auth_token

    @user = User.new(params[:user])
    @user.role = UserRole.find_by_name("administrator")

    if @user.save!

      # Activate and save again to really change 
      # state of this account.
      @user.activate!
      @user.save

      # No activation required for initial admin user.
      self.current_user = @user
      
      flash[:notice] = "You have created an administrative account on the system.  You may use this account to change system settings and assign privileges to other users."

      redirect_to system_settings_path
    else
      render :action => :new
    end
  end
  

  protected
  def first_time_only
    admin_role = UserRole.find_by_name("administrator")

    if !User.find(:all, :conditions => {
                    :role_id => admin_role.id
                  }).empty?
      flash[:error] = "Install cannot be run because an administrative " +
        "user already exists."

      redirect_to login_path
    end
  end
end
