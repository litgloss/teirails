class Content < ActiveRecord::Base
  acts_as_versioned

  belongs_to :creator, :class_name => "User"

  has_one :photo, :as => :imageable

  def filestring( len = 10 )
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    filestring = ""
    1.upto(len) { |i| filestring << chars[rand(chars.size-1)] }
    return filestring
  end

  def tei_data_to_xhtml
    xslt_file = "#{RAILS_ROOT}/tei/xhtml/tei.xsl"

    xslt_doc = self.tei_data

    filename = "/tmp/" + filestring + ".xhtml"

    fout = File.open(filename, 'w')
    fout.puts self.tei_data
    fout.close

    text = `xsltproc #{xslt_file} #{filename}`
    File.unlink(filename)

    return text
  end
end
