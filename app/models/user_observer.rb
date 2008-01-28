class UserObserver < ActiveRecord::Observer
  def after_create(user)
    user.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    user.save

    UserMailer.deliver_signup_notification(user)
  end
end
