class CreateUserRoles < ActiveRecord::Migration
  def self.up
    create_table :user_roles do |t|
      t.string :name, :nil => false
      
      # Specifies the relative level of permissions awarded to this
      # level.  A lower number indicates more permissions in the
      # system.  This will allow us to insert other permission levels
      # later without changing coding as much in all parts of the 
      # system.  There may be, however, a readability cost associated
      # with these levels.  To avoid this, obscure the access to this 
      # database field in the UserRole model, and instead force people
      # using this API to call the methods that return relative permission
      # levels from the User model.  
      # 
      # These include the methods for:
      #   * user.can_act_as?(UserRole)
      # 
      # Call these rather than messing with this integer value directly
      # for checking access levels!
      t.integer :level, :nil => false

      t.timestamps
    end
    
    UserRole.create :name => 'administrator', :level => 10
    UserRole.create :name => 'editor', :level => 20
    UserRole.create :name => 'protected_item_viewer', :level => 25
    UserRole.create :name => 'user', :level => 30

    # Modify the user model to accept the user_role id.
    add_column :users, :role_id, :integer, :default => 
      UserRole.find_by_name('user')
  end

  def self.down
    drop_table :user_roles
    remove_column :users, :role_id
  end
end
