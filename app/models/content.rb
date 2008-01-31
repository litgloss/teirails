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

    err_filename = "/tmp/" + filestring + ".xhtml"
    text = `xsltproc #{xslt_file} #{filename} 2> #{err_filename}`

    errors = File.read(err_filename)

    File.unlink(filename)
    File.unlink(err_filename)

    if !errors.empty?
      return "<html><body><h1>Whoops!</h1><pre>#{errors}</pre></body></html>"
    else
      return text
    end
  end
end
