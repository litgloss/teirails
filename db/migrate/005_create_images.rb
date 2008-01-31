class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      # So photos can be polymorphic.
      t.string  :imageable_type
      t.integer :imageable_id
      
      t.integer :parent_id
      t.string :content_type
      t.string :filename
      t.string :thumbnail
      t.integer :size
      t.integer :width
      t.integer :height
      
      t.string :title
      t.text :description

      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :images
  end
end
