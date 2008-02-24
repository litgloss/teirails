class CreateAudioFiles < ActiveRecord::Migration
  def self.up
    create_table :audio_files do |t|
      t.string  :audible_type
      t.integer :audible_id

      t.integer :parent_id
      t.string :content_type
      t.string :filename
      t.string :thumbnail
      t.integer :size

      t.string :title
      t.text :description

      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :audio_files
  end
end
