class AddForgottenPasswordFieldToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :password_reset_code, :string, :limit => 40
    add_column :users, :recently_forgot_password, :boolean, :default => false
    add_column :users, :recently_reset_password, :boolean, :default => false
    add_column :users, :activation_email_sent, :boolean, :default => false
  end

  def self.down
    remove_column :users, :password_reset_code
  end
end


