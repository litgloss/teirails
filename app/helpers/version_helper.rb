module VersionHelper
  def get_version_options(content_item, content_item_version)
    links = []

    links << link_to("Show", content_item_version_path(content_item, 
                                                       content_item_version.version))
    links << link_to("XML", formatted_content_item_version_path(content_item, 
                                                                content_item_version,
                                                                'xml'))

    if content_item_version.version != content_item.version
      links << link_to('Revert', 
                       revert_to_content_item_version_path(content_item, 
                                                           content_item_version.version),
                       :confirm => "Are you sure that you wish to revert to " + 
                       content_item_version.version.to_s + " of this document?",
                       :method => :post)
    end

    links.join(", ")
  end

  # Returns a string marker if this revision is the current one for
  # content item.
  def get_document_status(content_item, content_item_version)
    if content_item_version.version == content_item.version
      " (<strong>current version</strong>) "
    end
  end
end
