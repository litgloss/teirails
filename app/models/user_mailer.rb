class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
  
    @body[:url]  = "http://" + 
      SystemSetting.get("hostname") + 
      "/activate/#{user.activation_code}"
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
    @body[:url]  = "http://" + 
      SystemSetting.get("hostname") + "/"

    user.activation_email_sent = true
    user.save
  end

  def forgot_password(user)
    setup_email(user)
    @subject    += 'You have requested to change your password'
    @body[:url] = "http://" + 
      SystemSetting.get("hostname") + 
      "/reset_password/#{user.password_reset_code}" 
  end

  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "justin@phq.org"
      @subject     = "[#{SystemSetting.get("site_name")}] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
