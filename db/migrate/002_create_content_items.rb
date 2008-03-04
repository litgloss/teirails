class CreateContentItems < ActiveRecord::Migration
  def self.up
    create_table :content_items, :force => true do |t|
      t.text :tei_data

      t.integer :creator_id
      t.boolean :published, :default => false

      # Item is protected for copyright or other reason.
      # If this is the case, user must have at least role of 
      # "protected item viewer" or higher to see it.
      t.boolean :protected, :default => false

      # This item is only able to be modified by an administrator.
      # Generally, this is only used for "site" pages, e.g., "about"
      # site section.
      t.boolean :system, :default => false

      # Allows this item to be hidden in the public catalog listing,
      # even if other attributes (i.e., items is not a system item,
      # item is public) show that it should be shown.  Probably most
      # useful when the item is a supplementary reading that should
      # only be shown in search results or as an associated reading
      # with a primary text.
      t.boolean :hide_in_catalog, :default => true

      # Allows for "clones" which are copes of content 
      # items strictly for modification in a local workspace
      # of a user.  This is restricted in the ContentItem model
      # to a two-level hierarchy; clones are not allowed to
      # descend from each other.
      t.integer :parent_id

      t.timestamps
    end
  end

  def self.down
    drop_table :content_items
  end
end
