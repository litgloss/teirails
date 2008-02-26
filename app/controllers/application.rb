# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include ExceptionNotifiable
  include TeiHelper

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'd7a24d66393dda1c22b81c32b1058113'

  # Obnoxiously log message, used for spotting things in cluttered output.
  def oblog(msg)
    logger.info("\n\n\n#{msg.upcase}\n\n\n")
  end

  # Returns boolean value representing whether or not permission was granted 
  # to resource for read access, and redirects if failure occurs.
  def block_if_not_readable_by(user, object)
    filter_method = "readable_by?"
    block_on_permission_failure(user, object, filter_method)
  end

  # Returns boolean value representing whether or not permission was granted 
  # to resource for write access, and redirects if failure occurs.
  def block_if_not_writable_by(user, object)
    filter_method = "writable_by?"
    block_on_permission_failure(user, object, filter_method)
  end

  # Returns boolean value representing whether or not permission was granted 
  # to resource for create access, and redirects if failure occurs.
  # This acts on a class, of course, and not an instance of a class.
  def block_if_not_creatable_by(user, object)
    filter_method = "creatable_by?"
    return block_on_permission_failure(user, object, filter_method)
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

  def redirect_to_block(user, object)
    logger.error("User #{user} denied access to an instance of #{object.class}.")
    flash[:error] = "You do not have sufficient permissions to access this resource, event logged."

    redirect_to search_path
    return
  end


  ####################################
  ### Start PRIVATE methods
  ####################################

  private

  # Checks permissions on objects sent to us and redirects if
  # sufficient permissions don't exist.
  def block_on_permission_failure(user, object, filter_method)
    # First check to make sure that this object implements the correct method
    # and fail nicely if it doesn't.
    if object_implements_filter_method(object, filter_method)
      if object.send(filter_method.to_sym, user)
        true
      else
        redirect_to_block(user, object) and return false
      end
    else
      return false
    end
  end

  # Checks for proper implementation of method that we need for
  # security on a model, and errors out if this has not been
  # implemented.
  def object_implements_filter_method(object, filter_method)
    if not object.respond_to?(filter_method)
      logger.error("Warning: Object #{object.class} doesn't respond to #{filter_method}.")
      flash[:error] = "Access blocked based on results of reflection on object filter method."
      redirect_to search_path and return false
    end
  end
end
