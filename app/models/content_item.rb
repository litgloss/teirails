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
    jxml_to_erb_string(jxml_string)
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
    val.text
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
      '<%= render_partial "layouts/footer" %>' + "\n"

    textsubs = {
      '<JXML-renderheader><\/JXML-renderheader>' => header_string,
      '<JXML-renderfooter><\/JXML-renderfooter>' => footer_string
    }

    textsubs.keys.each do |s|
      logger.info("doing gsub of #{s} with #{textsubs[s]}.")
      jxml_string.gsub!(/#{s}/, textsubs[s])
    end

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
