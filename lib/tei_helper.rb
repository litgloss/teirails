require 'xml/libxml'

# Contains methods which use xml/libxml in order
# to glean useful information about a TEI document.
module TeiHelper
  protected

  include XML

  # Checks if a given string containaing a TEI document
  # is valid or not according to a dtd for TEI Lite.
  # Returns true if this string is a valid TEI document,
  # else an error message explaining how string does not follow
  # the dtd.
  def validate_tei_document(tei)
    dtd = Dtd.new("system", "#{RAILS_ROOT}/dtd/teilite.dtd")

    p =  Parser.string(tei)
    doc = p.parse
    res = doc.validate(dtd)
    
    if !res
      raise DTDValidationFailedError.new
    end
  end

end

class DTDValidationFailedError < StandardError
    
end
