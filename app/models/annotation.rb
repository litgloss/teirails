class Annotation < ActiveRecord::Base
  belongs_to :user

  # Render this annotation as rdf.
  def to_rdf
    
  end

  # Render all of these annotations in RDF format.
  def Annotation.to_rdf(annotations)
    
  end

  def to_xml
    @annotation = self
    ERB.new(File.read(RAILS_ROOT + '/app/views/annotations/show.xml.erb')).result(binding)
  end
end
