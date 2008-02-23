# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include TeiHelper

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'd7a24d66393dda1c22b81c32b1058113'

  # Obnoxiously log message, used for spotting things in cluttered output.
  def oblog(msg)
    logger.info("\n\n\n#{msg.upcase}\n\n\n")
  end

  # Checks whether a TEI string is valid XML and whether
  # or not it is valid according to a TEI DTD.  If document
  # has problems, set the flash[:error] variable to a useful
  # message and return false.  Else, return true.
  def validate_tei(tei_string)
    has_errors = false

    begin
      res = validate_tei_document(tei_string)
    rescue XML::Parser::ParseError
      flash[:error] = "Document does not contain valid XML." + 
        "  Please correct and try uploading again."


      has_errors = true
    rescue DTDValidationFailedError
      flash[:error] = "Document failed to validate against "  +
        "a schema for TEI Lite.  Please fix and try uploading again."
      
      has_errors = true
    end

    return !has_errors
  end

end
