class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles do |t|
      t.integer :user_id
      t.integer :photo_id

      t.string :last_name
      t.string :first_name

      t.string :address_line_1
      t.string :address_line_2

      t.string :city
      t.string :state

      t.string :country
      t.string :zip

      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :profiles
  end
end
