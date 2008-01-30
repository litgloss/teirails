class CreateAnnotations < ActiveRecord::Migration
  def self.up
    create_table :annotations, :force => true do |t|

      ### 
      # Begin RDF fields
      ###
      t.string :title
      t.string :content_type
      t.string :type
      t.string :annotates
      t.string :context
      t.string :language

      # Leaving this as a string to accept the RDF
      # field of the same name.  We'll probably also
      # store the user_id to properly connect this to user
      # though.  This will just hold whatever string the user
      # provides through their annotea client software.
      t.string :creator
      t.datetime :created
      t.datetime :date
      t.string :body
      t.string :root
      t.string :inreplyto
      t.string :encoding
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
