require 'xml/libxml_so'

# Contains methods which use xml/libxml in order
# to glean useful information about a TEI document.
module TeiHelper
  protected

  include XML

  # Checks if a given string containaing a TEI document is valid or
  # not according to a dtd for TEI Lite.  Returns true if this string
  # is a valid TEI document, else raises an exception of type
  # DTDValidationError.
  def validate_tei_document(tei)
    dtd = Dtd.new("system", "#{RAILS_ROOT}/dtd/teilite.dtd")

    p =  Parser.string(tei)

    # Server aborts if we don't catch this case.
    if p.string.empty?
      raise DTDValidationError.new(["input string was empty.  Did you specify an existing file?"])
      return false
    end

    doc = p.parse
    
    errors = []

    if doc.validate(dtd) { |message, error| errors << "#{error ? 'error' : 'warning'} : #{message}" }
      return true
    else
      raise DTDValidationError.new(errors)
    end
  end
end

class DTDValidationError < StandardError
  attr_accessor :errors

  def initialize(errors)
    @errors = errors
  end
end
