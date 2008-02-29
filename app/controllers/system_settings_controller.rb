class SystemSettingsController < ApplicationController
  append_before_filter :login_required

  def index
    @system_settings = SystemSetting.find(:all)
  end

  def new
    @system_setting = SystemSetting.new
  end

  def edit
    @system_setting = SystemSetting.find(params[:id])
  end

  def show
    @system_setting = SystemSetting.find(params[:id])
  end

  def update
    @system_setting = SystemSetting.find(params[:id])

    if @system_setting.update_attributes(params[:system_setting])
      flash[:notice] = 'System setting was successfully updated.'
      redirect_to system_setting_path(@system_setting)
    else
      render system_setting
    end

  end

  def create
    @system_setting = SystemSetting.new(params[:system_setting])

    if @system_setting.save
      flash[:notice] = 'System setting was successfully created.'
      redirect_to system_setting_path(@system_setting)
    else
      render :action => :new
    end

  end

  def destroy
    if SystemSetting.find(params[:id]).destroy
      redirect_to system_settings_path
    end
  end

  private
  def authorized?
    current_user.can_act_as?("administrator")
  end
end
