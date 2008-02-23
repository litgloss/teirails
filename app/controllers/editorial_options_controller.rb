class EditorialOptionsController < ApplicationController
  before_filter :login_required

  private
  def authorized?
    current_user.can_act_as?("editor")
  end
end
