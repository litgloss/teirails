require 'rexml/document'

# Content item which stores documents in TEI form.  This 
# class also contains methods for accessing and manipulating 
# some teiHeader elements.
class ContentItem < ActiveRecord::Base
  acts_as_versioned
  self.non_versioned_columns << 'published'

  include REXML

  belongs_to :creator, :class_name => "User"
  
  has_many :images, :as => :imageable

  has_one :system_page, :dependent => :destroy

  # Constant to prepend to temporary files that we create.
  TempFilePrefix = 'teirails'

  # There are a couple of levels of rendering required to change TEI
  # into a format that can be viewed on the site.  First, we change
  # the TEI data to "jxml" (Justin XML), which retains special tags
  # that we replace with ERB.  Then we render the ERB file, which
  # finally results in a string that can be passed back to the user.
  def tei_data_to_xhtml
    jxml_string = tei_to_jxml_string
    #logger.info("BEFORE litglosify\n#{jxml_string}")

    litglosified_string = litglosify(jxml_string)

    #logger.info("AFTER litglosify\n#{litglosified_string}")

    result = jxml_to_erb_string(litglosified_string)

    #logger.info("AFTER jxml_to_erb_string\n#{result}")

    result
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
                            :parent_id => self.id )

      ci.save
      return ci
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
      return true
    else
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
  # doesn't make sense to do this otherwise.
  def pull!(content_item)
    if self.related_to?(content_item)
      raise Exception.new("ContentItem objects need to be related " + 
                          "for pull to work.")
      return
    else
      self.tei_data = content_item.tei_data
      self.save
    end
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

  # Sets this object as a "system" content piece, which means 
  # that it is intended for use under a user-defined menu
  # item, rather than in the general category of Content Items.
  # In practice, Content Items which are "system" content are used
  # for static site pages, like the "About" page.
  def set_as_system_content!
    s = SystemPage.new
    self.system_page = s
    self.save
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

  # Returns boolean value representing whether or not this
  # item is a system page.
  def has_system_page
    !self.system_page.nil?
  end

  # Accepts a 
  def set_system_page_value(value)
    # Filter input before eval, even though RoR is too dumb to care
    # about this.
    if !value =~ /0|1/
      raise Exception.new("Bad value (#{value}) in input field for system page.")
      return
    end

    if (!eval(value).zero?)
      # Ignore if we already have a non-nil system page,
      # otherwise create one.
      if self.system_page.nil?
        self.system_page = SystemPage.new
      end
    else
      # Delete a system page if we have one.
      if !self.system_page.nil?
        s = self.system_page
        s.destroy
      end
    end
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
        logger.info("\n\nDoing body scan.\n\n")
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
  # of type "litgloss" and re-writes them to use overlib.  This is kind 
  # of hack-ish, but so are these types of "annotations," really.  They
  # shouldn't be stored in-line, but this code accomodates for lazy
  # and/or ignorant people who don't learn how to do good document markup
  # by hand.
  def litglosify(xhtml_content)

    new_doc = Document.new(xhtml_content)

    # Attribute search in XPath doesn't seem to work with namespaces... bug in REXML library?
    # Will work around for now.
    XPath.each( new_doc.root, '/html/body//a' ) do |href|
      if !href.attributes.get_attribute('type').nil? &&
          href.attributes.get_attribute('type').value.eql?('litgloss')

        # Construct the javascript tag.
        e = Element.new('a', nil, {:raw => :all})
        
        e.add_attribute('href', "/annotations/show/something")

        onmouseover_value = 'return overlib("' + 
          href.attributes.get_attribute('href').value + '");'

        e.add_attribute('onmouseover', onmouseover_value)
        e.add_attribute('onmouseout', 'return nd();')

        logger.info("\n\nwe made element #{e}\n\n")

        href.parent.insert_before( href, e)

        # Just taking the text of the old node may be a problem
        # if there is formatting contained in child nodes.
        e.text = href.text

        href.remove
      end
      
    end

    new_doc.to_s
  end

  def readable_by?(user)
    
    return case 
       
           when self.has_system_page && self.published?
             # We don't care about "protected" property on system
             # pages right now.
             true
             
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
    
    return case 
       
           when self.has_system_page
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
      if !c.has_system_page
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
      '<%= render_partial "layouts/sub_menu" -%>' + "\n" +
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
      logger.info("doing gsub of #{s} with #{textsubs[s]}.")
      jxml_string.gsub!(/#{s}/, textsubs[s])
    end

    logger.info("\n\n\nJXML STRING IS:\n\n#{jxml_string}")
    jxml_string
  end

  # Returns the contentof this object wih TEI replaced with XHTML.
  def tei_to_jxml_string
    xslt_file = "#{RAILS_ROOT}/tei/xhtml/tei.xsl"

    xslt_doc = self.tei_data

    tmpfile = Tempfile.new(TempFilePrefix + "_tei_")

    tmpfile.puts self.tei_data
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

end
