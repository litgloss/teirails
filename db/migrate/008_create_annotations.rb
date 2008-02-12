class CreateAnnotations < ActiveRecord::Migration
  def self.up
    create_table :annotations, :force => true do |t|

      t.text :rdf_data

      # Fields we store outside of the RDF content for 
      # querying efficiency.
      t.string :annotates

      # The Annotea protocol specification uses name "inReplyTo" for
      # this field.
      t.string :in_reply_to

      t.string :root

      ### 
      # End RDF fields
      ###

      # Not part of the RDF spec, used to link
      # to user id.
      t.integer :user_id

      # These are our own timestamps, the others above should be time
      # at which client recorded the RDF message.
      t.timestamps
    end
  end

  def self.down
    drop_table :annotations
  end
end
