# Parses requests from an annotea server for "new" and "update"
# requests.  Tries to follow specifications online at:
# http://www.w3.org/2002/12/AnnoteaProtocol-20021219.  
# 
# This code is based on the code from the Zope annotea server
# (python), ZAnnot, written by Brett Hendricks and Yasushi Yamazaki,
# (LGPL) code available at:
#
#      http://rhaptos.org/cgi-bin/viewcvs.cgi/ZAnnot/
#
# Author: Justin S. Leitgeb <leitgebj AT hcoop DOT net>

require 'xml/libxml'
class AnnoteaRequestParser

  @logger = nil
  @xml_request = nil
  @annotation = nil
  
  @isBodyUri = nil

  # Annotation namespaces
  Namespaces = [ "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
                 "http://www.w3.org/2000/10/annotation-ns#",
                 "http://www.w3.org/2001/03/thread#",
                 "http://www.w3.org/1999/xx/http#",
                 "http://purl.org/dc/elements/1.0/",
                 "http://purl.org/dc/elements/1.1/" ]

  # Possible tag names that we will return.  Values
  # in hash are possible Namespaces.
  Tagnames = { 
    :type =>      [Namespaces[0]],
    :annotates => [Namespaces[1]],
    :context =>   [Namespaces[1]],
    :title =>     [Namespaces[4], Namespaces[5]],
    :language =>  [Namespaces[4], Namespaces[5]],
    :creator =>   [Namespaces[4], Namespaces[5]],
    :created =>   [Namespaces[1]],
    :date =>      [Namespaces[4], Namespaces[5]],
    :root =>      [Namespaces[2]],
    :inReplyTo => [Namespaces[2]]
  }
  

  @tagcontents = {}

  def initialize(request_raw_post, annotation, logger)

    @annotation = annotation
    @xml_request = XML::Document.new(request_raw_post)
    @logger = logger


    @isBodyUri = false

    @logger.info("isbody uri val == #{@isBodyUri}")
    
    # @logger.info("Doc as XML:\n#{@xml_request}")
    initialize_annotation_from_rdf
  end

  private
  def initialize_annotation_from_rdf
    # For each Tagname, we want any matching elements
    # in valid namespaces.
    Tagnames.keys.each do |k|
      @logger.info("Hey, a key is #{k}")
      
    end
    
  end

  # This annotation either refers to an already
  # existing body, or it 
  def initialize_document_body
  end
end
