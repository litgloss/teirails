module ImagesHelper
  def show_image_thumbnails
    image_text = "<ul class=\"thumbnailImages\">\n"

    @images.each do |p|
      image_text += "<li>" + image_thumbnail_and_link(p) + "</li>\n"
    end

    image_text += "</ul>\n\n"

    return image_text
  end

  def streamed_image_tag(image)
    width = image.width
    height = image.height

    tag = "<img src=\"" +
      stream_image_path(image) + "\"" +
      " height=\"#{height}\"" +
      " width=\"#{width}\">"

    return tag
  end

  # Streams image thumbnail in a link
  # to medium-sized image.  Assumes we are passed
  # the parent image object.
  def image_thumbnail_and_link(image)
    small_image = Image.find(:first, :conditions => {
                                :parent_id => image.id,
                                :thumbnail => "small"
                              })

    medium_image = Image.find(:first, :conditions => {
                               :parent_id => image.id,
                               :thumbnail => "medium"
                             })

    text = link_to( streamed_image_tag(small_image),
                    image_path(medium_image) )

    return text
  end
end
