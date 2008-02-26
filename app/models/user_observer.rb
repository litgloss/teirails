class UserObserver < ActiveRecord::Observer
  def after_create(user)
    user.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    user.save
    
    if !user.can_act_as?("administrator")
      UserMailer.deliver_signup_notification(user)
    end
  end

  def after_save(user)  
    UserMailer.deliver_activation(user) if user.active? && 
      !user.activation_email_sent &&
      !user.can_act_as?("administrator")

    UserMailer.deliver_reset_password(user) if user.recently_reset_password?
  end
end
