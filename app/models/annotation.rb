# Class stores the entire RDF of the annotation as it is sent to us so
# that it can be reproduced in its entirety later.  In addition, we
# duplicate the following RDF fields in independent ActiveRecord
# fields for local querying efficiency: annotates, inReplyTo, root.
#
# The only other modification to this record is a "user_id" field,
# which will (eventually) be used to map the submitter of an annotation
# to a user of our CMS.
#
# Author: Justin S. Leitgeb <leitgebj AT hcoop DOT net>

require 'rexml/document'
class Annotation < ActiveRecord::Base
  include REXML

  belongs_to :user

  # Annotation namespaces
  NAMESPACES = [ "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
                 "http://www.w3.org/2000/10/annotation-ns#",
                 "http://www.w3.org/2001/03/thread#",
                 "http://www.w3.org/1999/xx/http#",
                 "http://purl.org/dc/elements/1.0/",
                 "http://purl.org/dc/elements/1.1/" ]

  # Possible tag names that we will return.  Values
  # in hash are possible Namespaces.
  TAGNAMES = {
    :type =>         [NAMESPACES[0]],
    :annotates =>    [NAMESPACES[1]],
    :context =>      [NAMESPACES[1]],
    :title =>        [NAMESPACES[4], NAMESPACES[5]],
    :language =>     [NAMESPACES[4], NAMESPACES[5]],
    :creator =>      [NAMESPACES[4], NAMESPACES[5]],
    :created =>      [NAMESPACES[1]],
    :date =>         [NAMESPACES[4], NAMESPACES[5]],
    :root =>         [NAMESPACES[2]],
    :inReplyTo =>    [NAMESPACES[2]],
    :Body =>         [NAMESPACES[3]],
    :ContentType =>  [NAMESPACES[3]]
  }

  # Returns the document body.  This might either
  # be a resource, if it is an "external body", or
  # a full XML document.
  def body
    elt = get_doc_root.find_first_recursive do |node|
      node.local_name.eql?('Body') &&
        TAGNAMES[:Body].include?(node.namespace)
    end
    return elt.children
  end

  def body_content_type
    return self.get_tag_value('ContentType')
  end

  # Returns true if this RDF document has an "external body" -
  # that is, if it just has a reference to another document
  # in a resource string in the body tag.
  # XXX Implement me!
  def body_uri?
    raise Exception.new, "body_uri? method is unimplemented!"
  end

  # Returns the resource value for this tag if it exists, otherwise we
  # try to return the text contents of the element.  If all else
  # fails, returns nil.
  def get_tag_value(local_name)
    elt = get_doc_root.find_first_recursive do |node|
      node.local_name.eql?(local_name) &&
        TAGNAMES[local_name.to_sym].include?(node.namespace)
    end
    if elt.nil?
      return nil
    elsif !elt.attributes['resource'].nil?
      return elt.attributes['resource']
    elsif !elt.get_text.nil?
      return elt.get_text
    else
      return nil
    end
  end

  # Annotation RDF records generally have two type fields,
  # where the first is always "Annotation".  Return the
  # second type, since this is the interesting one.
  def get_type
    elt = nil

    get_doc_root.each_recursive do |node|
      if node.local_name.eql?('type') &&
        TAGNAMES[:type].include?(node.namespace)
        elt = node
      end
    end

    if elt.nil?
      return nil
    else !elt.attributes['resource'].nil?
      return elt.attributes['resource']
    end
  end

  # Set meta fields "annotates", "in_reply_to" and "root"
  # for querying efficiency.
  def set_meta_fields
    root = get_doc_root

    self.annotates = get_tag_value('annotates')
    self.root = get_tag_value('root')
    self.in_reply_to = get_tag_value('inReplyTo')

    self.save
  end

  def body_to_xml
    @annotation = self
    ERB.new(File.read(RAILS_ROOT + '/app/views/annotations/body.xml.erb')).result(binding)
  end

  def to_xml
    @annotation = self
    ERB.new(File.read(RAILS_ROOT + '/app/views/annotations/show.xml.erb')).result(binding)
  end

  # Returns an XML::Element representing the document root
  # of this RDF object.
  def get_doc_root
    Document.new(self.rdf_data).root
  end

  # Returns the abbreviated form of a namespace uri for the root
  # of this rdf document.
  def get_namespace_hash_for(namespace_uri)
    get_doc_root.namespaces.each do |ns|
      if ns[1].eql?(namespace_uri)
        return { ns[0] => ns[1] }
      end
    end

    nil
  end
end
