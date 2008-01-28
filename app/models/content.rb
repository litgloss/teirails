class Content < ActiveRecord::Base
  acts_as_versioned
  belongs_to :creator, :class_name => "User"

  def filestring( len = 10 )
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    filestring = ""
    1.upto(len) { |i| filestring << chars[rand(chars.size-1)] }
    return filestring
  end


  def get_xhtml_teidata
    xslt_file = '/afs/hcoop.net/user/l/le/leitgebj/CODE/tei-xsl-current/p5/xhtml/tei.xsl'

    xslt_doc = self.teidata
    
    filename = "/tmp/" + filestring + ".xhtml"

    fout = File.open(filename, 'w')
    fout.puts self.teidata
    fout.close

    text = `xsltproc #{xslt_file} #{filename}`
    File.unlink(filename)
    
    return text
  end
end
