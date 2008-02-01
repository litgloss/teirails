class Content < ActiveRecord::Base
  acts_as_versioned

  belongs_to :creator, :class_name => "User"

  has_one :photo, :as => :imageable

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

  private

  def jxml_to_erb_string(jxml_string)
    header_string = "\n" +
      '<%= render_partial "layouts/main_logo" %>' +
      "\n" +
      '<%= render_partial "layouts/main_menu" %>' + "\n" +
      '<div id="mainContent">' + "\n"

    footer_string = "\n</div>" +
      '<%= render_partial "layouts/footer" %>' + "\n"

    textsubs = {
      '<JXML-renderheader\/>' => header_string,
      '<JXML-renderfooter\/>' => footer_string
    }

    textsubs.keys.each do |s|
      logger.info("doing gsub of #{s} with #{textsubs[s]}.")
      jxml_string.gsub!(/#{s}/, textsubs[s])
    end

    return jxml_string
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
