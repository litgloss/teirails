module ImagesHelper
  def show_image_thumbnails
    image_text = "<ul class=\"thumbnailImages\">\n"

    @images.each do |p|
      image_text += "<li>" + image_thumbnail_and_link(p) + "</li>\n"
    end

    image_text += "</ul>\n\n"

    return image_text
  end

  def get_associated_object_show_link(image)
    controller = eval(image.imageable_type.camelize).table_name.singularize

    # Profiles are a nested route, add prefix for these.
    if controller =~ /profile/
      controller = "user_" + controller
    end

    link_to("#{image.imageable_type.humanize.downcase} id #{image.imageable_id}", 
            eval(controller + "_path(" + image.imageable_id.to_s + ")"))
  end

  def get_associated_object_show_link_from_type_and_id(obj_type, obj_id)
    controller = eval(obj_type.camelize).table_name.singularize

    # Cases for different paths based on nested routes.
    case controller
    when /profile/
      controller = "user_" + controller
      profile = Profile.find(obj_id)

      user = profile.user
      link_to("user profile", user_profile_path(user))
                                                
    when /litgloss/
      controller = "content_item_litglosses"
      litgloss = Litgloss.find(obj_id)
      content_item = litgloss.content_item
      link_to("litgloss", content_item_litgloss_path(content_item, 
                                                     litgloss))
    when /content_item/
      obj = eval(obj_type.camelize).find(obj_id)
      if obj.title.nil?
        title = "Unknown title"
      else
        title = obj.title
      end
      link_to("Content item, \"" + title + '"', 
              eval(controller + "_path(" + obj_id.to_s + ")"))
    else
      link_to("#{obj_type.humanize.downcase} id #{obj_id}", 
              eval(controller + "_path(" + obj_id.to_s + ")"))
    end
  end

  # Returns the links that a user is able to use in
  # order to manage this object, if any.
  def get_management_links(image)
    links = []
    if image.imageable_type.eql?("content_item")
      if image.writable_by?(current_user)
        links << link_to('Edit Image', edit_image_path(image))
      end
        
      if current_user.can_act_as?("administrator") ||
        image.get_associated_object.writable_by?(current_user)
        links << link_to('Delete Image', { 
                           :action => "destroy",
                           :id => image 
                         },
                         :confirm => "Are you sure?",
                         :method => :delete)
      end
      
    elsif image.imageable_type.eql?("profile")
      if current_user == User.find(image.imageable_id) ||
          current_user.can_act_as?("administrator")
        links << link_to('Edit Image', edit_image_path(image))
        links << link_to('Delete Image', { 
                           :action => "destroy",
                           :id => image 
                         },
                         :confirm => "Are you sure?",
                         :method => :delete)
        end
    end

    links.join(" | ")
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
