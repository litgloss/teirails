require 'rexml/document'

# Content item which stores documents in TEI form.  This class also
# contains methods for accessing and manipulating some teiHeader
# elements.
class ContentItem < ActiveRecord::Base
  acts_as_versioned

  self.non_versioned_columns << 'published'
  self.non_versioned_columns << 'protected'

  include TeiHelper

  include REXML

  belongs_to :creator, :class_name => "User"
  
  has_many :images, :as => :imageable

  has_many :audio_files, :as => :audible

  has_many :litglosses

  has_many :content_item_group_links, :dependent => :destroy
  has_many :groups, :through => :content_item_group_links, :source => 
    :content_item_group

  # Get rid of clones when a perent is destroyed, and all associated
  # media objects.  Don't do this with a normal "dependent => destroy"
  # statement since that would also delete items associated with
  # parent because of the general select method for these objects that
  # we've overridden.
  before_destroy { |record| 
    ContentItem.destroy_all "parent_id = #{record.id}"
    Litgloss.find(:all, :conditions => {
                    :content_item_id => record.id
                  }).each do |lg|
      lg.destroy
    end

    AudioFile.find(:all, :conditions => {
                     :audible_id => record.id,
                     :audible_type => "content_item"
                   }).each do |af|
      af.destroy
    end

    Image.find(:all, :conditions => {
                 :imageable_id => record.id,
                 :imageable_type => "content_item"
               }).each do |i|
      i.destroy
    end
  }

  # Constant to prepend to temporary files that we create.
  TempFilePrefix = 'teirails'

  def ContentItem.to_phrase
    "content item"
  end


  # There are a couple of levels of rendering required to change TEI
  # into a format that can be viewed on the site.  First, we change
  # the TEI data to "jxml" (Justin XML), which retains special tags
  # that we replace with ERB.  Then we render the ERB file, which
  # finally results in a string that can be passed back to the user.
  def tei_data_to_xhtml(tei_data, request)
    jxml_string = tei_to_jxml_string(tei_data)

    litglosified_string = litglosify(jxml_string)

    # Modify output for brain-dead browsers.
    if request.user_agent.downcase =~ /msie/
      litglosified_string = 
        modify_litglossed_output_for_garbage_browsers(litglosified_string)
    end

    result = jxml_to_erb_string(litglosified_string)

    result
  end
  
  # Removes a litgloss id tag from an XML string.
  def delete_litgloss_tag_by_id(litgloss_id)
    xml_object = doc
    XPath.each(xml_object,
               "/TEI/text//ref") do |e|
      if !e.attributes['target'].nil? &&
          e.attributes['type'].eql?('litgloss') &&
          e.attributes['target'] =~ /\/#{litgloss_id}$/

        e.children.each{ |c| e.parent.insert_after(e, c) }
        e.remove
      end
    end
    
    return xml_object
  end

  def delete_litgloss_tag_by_id!(litgloss_id)
    self.tei_data = delete_litgloss_tag_by_id(litgloss_id).to_s
    self.save
  end
  
  def delete_litgloss!(litgloss)
    self.tei_data = delete_litgloss_tag_by_id(litgloss.id.to_s).to_s
    self.save
  end

  # Returns boolean value representing whether or not this node 
  # has ancestors which are reference tags.
  def xml_element_has_reference_ancestors?(element)
    ref = XPath.first( element, 'ancestor::ref' )
    return !ref.nil?
  end


  # Breaks the input string into chunks occurring 
  # before an specific occurrence of a term in a string,
  # the occurrance searched for, and that occurring 
  # after this occurrence.  Returns an array of these
  # string portions.  The third parameters is an 
  # integer representing the occurrence to match in this
  # string.  It is 0-based!
  def tokenize_on_occurrence(string, term, count)
    pre_string = ""
    match = ""
    post_string = ""
    
    regexp_escaped_term = Regexp.escape(term)

    # Return nil if there aren't enough matches of the
    # string of the specified term to tokenize.
    if string.scan(/#{regexp_escaped_term}/m).size < count
      return nil
    end

    match_count = 0
    string.scan(/(.*?)(\b)(#{regexp_escaped_term})(\b)/m) do 
      |pre, pre_boundary, match, post_boundary|
    
      if match_count < count
        pre_string += pre + pre_boundary + match + post_boundary
      elsif count == match_count
        pre_string += pre + pre_boundary
        match = match
        post_string = post_boundary
      else
        post_string += pre + pre_boundary + match + post_boundary
      end

      match_count += 1
    end

    term_beginning = Regexp.escape(pre_string + match + post_string)
    
    remaining_text = string.match(/#{term_beginning}(.*)$/m)
    
    post_string += $1
    
    [pre_string, match, post_string]
  end

  def insert_temporary_ref_tags_for_string_match(xml_object, text_to_match,
                                                 match_count = 0)

    escaped_term_regexp = Regexp.escape(text_to_match)

    scanning_regexp = Regexp.new(/\b#{escaped_term_regexp}\b/)

    XPath.each( xml_object, '/TEI/text//text()') do |text_element|
      if !xml_element_has_reference_ancestors?(text_element)

        # Broken into two patterns because pattern (1) is used the
        # majority of the time and it is less processor-intensive.
        if scanning_regexp.match(text_element.value)
          regexp_with_backreferences = 
            Regexp.new(/^(.*?\b)(#{escaped_term_regexp})(\b.*)$/m)

          if text_element.value =~ regexp_with_backreferences
            
            text_before_term = $1
            term_match = $2
            text_after_term = $3

            # Build new tag.
            ref_tag = Element.new('ref', nil, {:raw => :all})
            ref_tag.add_attribute('type', 'newlitgloss')

            encoded_term = ERB::Util.url_encode(text_to_match)

            target_url = "/content_items/#{self.id}/litglosses/new" + 
              "?term=#{encoded_term}&" +
              "count=#{match_count}"

            ref_tag.add_attribute('target', target_url)
            
            ref_tag.text = term_match
            
            text_element.value = text_before_term.to_s
            text_element.next_sibling = ref_tag
            ref_tag.next_sibling = Text.new(text_after_term.to_s)
            
            match_count += 1

            # Recursive call allows this algorithm to handle cases where
            # text_after_term contains another match for this
            # annotation.
            insert_temporary_ref_tags_for_string_match(xml_object, 
                                                       text_to_match,
                                                       match_count)
          end
        end
      end
    end

    xml_object
  end

  # Creates an "ref" element in the document that will 
  # appear as "glossed" text.
  def create_glossed_link(xml_object, litgloss)
    escaped_term_regexp = Regexp.escape(litgloss.term)

    scanning_regexp = Regexp.new(/\b#{escaped_term_regexp}\b/m)

    match_count = 0

    XPath.each( xml_object, '/TEI/text//text()') do |text_element|
      if !xml_element_has_reference_ancestors?(text_element)
        if text_element.value.scan(scanning_regexp).size + match_count >
            litgloss.count

          res = tokenize_on_occurrence(text_element.value, litgloss.term,
                                 litgloss.count - match_count)

          logger.info("res val == #{res}")
          text_before_term = res[0]
          term_match = res[1]
          text_after_term = res[2]
          
          # Build new tag.
          ref_tag = Element.new('ref')
          ref_tag.add_attribute('type', 'litgloss')
          
          encoded_term = ERB::Util.url_encode(term_match)
          
          target_url = litgloss.path
          
          ref_tag.add_attribute('target', target_url)
          
          ref_tag.text = term_match
          
          text_element.value = text_before_term.to_s
          text_element.next_sibling = ref_tag
          ref_tag.next_sibling = Text.new(text_after_term.to_s)

          return xml_object
        else
          match_count += text_element.value.scan(scanning_regexp).size
        end
      end
    end
  end


  # Creates a clone of this content item in the workspace 
  # of the user specified.  Will not work if the content item
  # that this method is called on is already a clone -- returns
  # "nil" in this case.  If clone is successful, returns the cloned
  # content item object.  Named private_clone methods to avoid confusion
  # with the ActiveRecord::Base#clone method.
  def private_clone(user)
    if !self.private_clone?
      ci = ContentItem.new( :creator => user,
                            :published => false,
                            :tei_data => self.tei_data,
                            :parent_id => self.id,
                            :system => self.system
                          )

      if ci.save
        return ci
      else
        return nil
      end
    else
      return nil
    end
  end

  # Returns boolean value indicating whether or not this content
  # item is a clone.
  def private_clone?
    return !self.parent_id.nil?
  end

  # Returns boolean value indicating whether or not this 
  # content item is related to the one passed to us.
  def related_to?(content_item)
    if self.parent_id == content_item.id ||
        self.id == content_item.parent_id
      logger.info("It is related.")
      return true
    else
      logger.info("It is NOT related.")
      return false
    end
  end

  # Returns the parent of this content item if it
  # is a clone.  Else, returns nil.
  def parent
    if self.parent_id.nil?
      return
    else
      return ContentItem.find(self.parent_id)
    end
  end

  # Returns an array of the clones of this content item.
  def private_clones
    private_clones = []

    ContentItem.find(:all, :conditions => {
                       :parent_id => self.id
                     })
  end

  # Copies the tei_data of the ContentItem given to us
  # as parameter 1 into the body of this item.  Returns
  # true if this operation succeeded, or raises an exception
  # and returns nil otherwise.  Pull only works if items are 
  # related to one another as parent and child, since it 
  # doesn't make sense to do this otherwise.  The pull
  # operation checks to see if the current item has any litglosses
  # or images associated with it.  If it does, it copies these 
  # items to the parent.  Depending on the permissions of the 
  # user, this may or may not make them lose write permission
  # to this associated object.
  def pull!(content_item)
    if !self.related_to?(content_item)
      raise Exception.new("ContentItem objects need to be related " + 
                          "for pull to work.")
      return
    else
      self.tei_data = content_item.tei_data
      
      # Synchronize images, audio files and litglosses.  If we are the
      # parent, change these objects to reference our own space.  If
      # we are the child we don't do anything, since the methods for
      # grabbing images associated with this item are overriden to
      # include objects associated with the parent (for read access
      # only).
      if content_item.private_clone?
        Litgloss.find(:all, :conditions => {
                        :content_item_id => content_item.id
                      }).each do |l|

          l.content_item_id = self.id
          l.save
        end

        AudioFile.find(:all, :conditions => {
                         :audible_type => "content_item",
                         :audible_id => content_item.id
                       }).each do |af|
          
          af.audible_id = self.id
          af.save
        end
        
        Image.find(:all, :conditions => {
                     :imageable_type => "content_item",
                     :imageable_id => content_item.id
                   }).each do |i|
          i.imageable_id = self.id
          i.save
        end
      end

      self.save
    end
  end

  # Returns all images associated with this item or its parent.
  def images
    imgs = []

    if self.private_clone?
      self.parent.images.each do |i|
        imgs << i
      end
    end

    Image.find(:all, :conditions => {
                 :imageable_id => self.id,
                 :imageable_type => "content_item",
                 :parent_id => nil
               }).each do |i|
      imgs << i
    end

    imgs
  end

  def audio_files
    afs = []

    if self.private_clone?
      self.parent.audio_files.each do |a|
        afs << a
      end
    end

    AudioFile.find(:all, :conditions => {
                     :audible_id => self.id,
                     :audible_type => "content_item",
                     :parent_id => nil
                   }).each do |a|
      afs << a
    end

    afs
  end

  # Returns all litglosses associated with this item or its parent.
  def litglosses
    lgs = []

    if !self.parent_id.nil?
      Litgloss.find(:all, :conditions => {
                      :content_item_id => self.parent.id
                    }).each do |l|
        lgs << l
      end
    end

    Litgloss.find(:all, :conditions => {
                    :content_item_id => self.id
                  }).each do |l|
      lgs << l
    end

    lgs
  end

  # Given an array of content items, removes those marked as
  # being a (private) clone.
  def ContentItem.remove_cloned_content_items(content_items)
    new_content_items = []

    content_items.each do |ci|
      if !ci.private_clone?
        new_content_items << ci
      end
    end

    new_content_items
  end

  # Returns a XML::Document of this tei_data
  def doc
    REXML::Document.new(self.tei_data)
  end

  # Returns the document title, if found, in the XML document
  # header.
  def title
    val = XPath.first(doc, '/TEI/teiHeader/fileDesc/titleStmt/title')

    if val.nil? || val.text.nil?
      ""
    else
      val.text
    end
  end

  # Returns (currently) the first language in the profileDesc
  # section of the teiHeader.
  def primary_language
    val = XPath.first(doc, '/TEI/teiHeader/profileDesc/langUsage/language')
    if !val.nil?
      val.text
    else
      nil
    end
  end

  # Returns an array of all languages defined under the profileDesc
  # section of the teiHeader.
  def languages
    languages = []
    XPath.each(doc, '/TEI/teiHeader/profileDesc/langUsage/language') do |l|
      languages << l.text
    end
    
    languages
  end

  # Returns an array of authors in this content item.
  def authors
    authors = []
    XPath.each(doc, '/TEI/teiHeader/fileDesc/titleStmt/author') do |a|
      authors << a.text
    end
    
    authors
  end

  # Returns the contents of the document body.
  def body
    return XPath.first(doc, '/TEI/text/body')
  end

  # Add an author to the TEI header.
  def add_author(author)
    mydoc = self.doc

    new_author_elt = Element.new('author')
    new_author_elt.text = author

    titlestmt = XPath.first(mydoc, '/TEI/teiHeader/fileDesc/titleStmt')
    titlestmt.add_element(new_author_elt)

    self.tei_data = mydoc.to_s
    self.save
  end

  # Set the value of the title field and save resulting TEI 
  # document to body.
  def title=(val)
    mydoc = self.doc

    old_title = XPath.first(mydoc, '/TEI/teiHeader/fileDesc/titleStmt/title')

    # Replace old title if it exists.
    if !old_title.nil?
      old_title.text = val
    else
      new_title = Element.new('title')
      titlestmt = XPath.first(mydoc, '/TEI/teiHeader/fileDesc/titleStmt')
      titlestmt.add_element(new_title)
    end

    self.tei_data = mydoc.to_s
    self.save
  end

  # Returns a set of content items matching this term
  # in the specified fields.
  def ContentItem.find_matching(search_term, search_fields)
    content_items = []

    search_fields.each do |s|
      case s
      when :titles
        ContentItem.find(:all).each do |c|
          if c.title =~ /#{search_term}/i
            if !content_items.include?(c)
              content_items << c
            end
          end
        end

      when :authors
        ContentItem.find(:all).each do |c|
          c.authors.each do |a|
            if a =~ /#{search_term}/i
              if !content_items.include?(c)
                content_items << c
              end
            end
          end
        end

      when :bodies
        ContentItem.find(:all).each do |c|
          if c.body.to_s =~ /#{search_term}/i
            if !content_items.include?(c)
              content_items << c
            end
          end
        end
      end

    end
    
    content_items
  end

  # When given a string of valid xhtml content, parses all href elements
  # of type "litgloss" and re-writes them to use overlib. 
  def litglosify(xhtml_content)

    new_doc = Document.new(xhtml_content)

    # Attribute search in XPath doesn't seem to work with
    # namespaces... bug in REXML library?  Will work around for now.
    XPath.each( new_doc.root, '/html/body//a' ) do |href|
      if !href.attributes.get_attribute('type').nil? &&
          href.attributes.get_attribute('type').value.eql?('litgloss')

        href.attributes.get_attribute('href').value =~ /litglosses\/(\d+)$/
        
        litgloss_id = $1
        
        if !litgloss_id.nil?
          if Litgloss.find_by_id(litgloss_id)
        
            litgloss = Litgloss.find(litgloss_id)

            # Construct the javascript tag.
            e = Element.new('a', nil, {:raw => :all})
        
            show_litgloss_url = "/content_items/#{self.id}/litglosses/" + 
              "#{litgloss.id}"

            e.add_attribute('href', show_litgloss_url)

            # Do an imagegloss if we have images, otherwise
            # just show text.
            if litgloss.images.empty? ||
                !litgloss.imagegloss?

              onmouseover_value = 'return overlib(' + 
                'unescape("' + 
                litgloss.url_encoded_explanation + 
                '"));'
            else
              image = 
                litgloss.images.find(:first,
                                     :conditions => {
                                       :thumbnail => "small"
                                     })

              image_url = "/images/#{image.id}/stream"

              onmouseover_value = 'return overlib(' + 
                '"",' + 
                'BACKGROUND,' +
                'unescape("' +
                ERB::Util.url_encode(image_url) +
                '"),FGCOLOR,' + '"",' +
                "WIDTH," + image.width.to_s + "," +
                "HEIGHT," + image.height.to_s +
                ');'
            end
            
            e.add_attribute('onmouseover', onmouseover_value)
            e.add_attribute('onmouseout', 'return nd();')

            e.add_attribute('class', "litgloss")

            href.parent.insert_before( href, e)

            # Just taking the text of the old node may be a problem
            # if there is formatting contained in child nodes.
            e.text = href.text
            
            href.remove
          else
            logger.info("Couldn't find litgloss with id #{litgloss_id} in content item id #{self.id}.")
          end
        else
          logger.info("Found nil litgloss id in content item #{self.id}.")
        end

      elsif !href.attributes.get_attribute('type').nil? &&
          href.attributes.get_attribute('type').value.eql?('newlitgloss')
        href.attributes['class'] = "newlitgloss"
      end
    end

    new_doc.to_s
  end


  # Makes overlib script tag self-closing to compensate for the IE bug described
  # here:
  # http://webbugtrack.blogspot.com/ \
  #          2007/08/bug-153-self-closing-script-tag-issues.html
  def modify_litglossed_output_for_garbage_browsers(litglossed_output)
    litglossed_output.sub!(/<script type='text\/javascript' src='\/javascripts\/overlib.js'\/>/, "<script type='text/javascript' src='/javascripts/overlib.js'></script>")

    litglossed_output
  end

  def readable_by?(user)
    
    return case 
           when user.class == Symbol
             self.published?

           when self.system? && self.published?
             # We don't care about "protected" property on system
             # pages right now.
             true
             
           when !self.parent_id.nil?
             # Clone case
             user.can_act_as?("administrator") ||
               user == self.creator

           when self.published? && !self.protected? then 
             true
             
           when self.published? && !self.protected? then
             (user.class == User)
             
           when self.published? && self.protected? then
             (user.class == User) && 
               (user.can_act_as?("protected_item_viewer"))
             
           when !self.published?
             user.can_act_as?("editor")
           else
             false
             
           end
  end

  def writable_by?(user)
    if user.class == Symbol || user.nil?
      return false
    end
    
    return case 
       
           when self.system?
             user.can_act_as?("administrator")
             
           when self.private_clone?
             user.can_act_as?("administrator") ||
             user.id == self.creator_id
             
           else
             user.can_act_as?("editor")
           end
  end


  # Given an array of content items, removes those that have system
  # pages.
  def ContentItem.remove_system_content_items(content_items)
    new_content_items = []

    content_items.each do |c|
      if !c.system?
        new_content_items << c
      end
    end
    
    new_content_items
  end

  # Given an array of content items and a user, returns the
  # array of content items that this user has access to.
  def ContentItem.filter_content_item_ary_by_user_level(content_items, user)
    new_cis = []
    content_items.each do |c|
      if c.readable_by?(user)
        new_cis << c
      end
    end

    return new_cis
  end

  private

  def jxml_to_erb_string(jxml_string)
    header_string = "\n" +
      '<%= render_partial "layouts/header_components" %>' +
      "\n" +
      '<%= render_partial "layouts/main_menu" %>' + "\n" +
      '<div id="mainContent">' + "\n" +
      '<%= render_partial "layouts/sub_menu_components" -%>' + "\n" +
      '<%= render_partial "layouts/flashes" -%>'

    footer_string = "\n" +
      '<%= render_partial "content_items/footer" %>' + "\n" +
      '<%= render_partial "layouts/footer" %>' + "\n"

    # Depending on the XML parsing engine we put these pages through, 
    # our own tags are either self-closing or not.  Check for both
    # and remove unnecessary ones for efficiency later.
    textsubs = {
      '<JXML-renderheader></JXML-renderheader>' => header_string,
      '<JXML-renderfooter></JXML-renderfooter>' => footer_string,
      '<JXML-renderheader/>' => header_string,
      '<JXML-renderfooter/>' => footer_string,
    }

    textsubs.keys.each do |s|
      jxml_string.gsub!(/#{s}/, textsubs[s])
    end

    jxml_string
  end

  # Returns the contentof this object wih TEI replaced with XHTML.
  def tei_to_jxml_string(tei_data)
    xslt_file = "#{RAILS_ROOT}/tei/xhtml/tei.xsl"

    tmpfile = Tempfile.new(TempFilePrefix + "_tei_")

    tmpfile.puts tei_data
    tmpfile.flush

    err_tmpfile = Tempfile.new(TempFilePrefix + "_tei_err_")
    text = `xsltproc #{xslt_file} #{tmpfile.path} 2> #{err_tmpfile.path}`

    errors = File.read(err_tmpfile.path)

    tmpfile.close!
    err_tmpfile.close!

    if !errors.empty?
      return "<html><body><h1>Whoops!</h1><pre>#{errors}</pre></body></html>"
    else
      return text
    end
  end

  protected
  def validate
    begin
      res = validate_tei_document(self.tei_data)
    rescue XML::Parser::ParseError => e
      errors.add(:tei_data, "- Document is not well-formed XML.")
    rescue DTDValidationError => dtd_ve
      dtd_ve.errors.each do |e|
        errors.add(:tei_data, "- " + e)
      end
    end
  end

end
