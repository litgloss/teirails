# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'd7a24d66393dda1c22b81c32b1058113'

  # Obnoxiously log message, used for spotting things in cluttered output.
  def oblog(msg)
    logger.info("\n\n\n#{msg.upcase}\n\n\n")
  end
end
