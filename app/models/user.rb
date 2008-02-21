require 'digest/sha1'
class User < ActiveRecord::Base
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  has_many :content_items, :foreign_key => :creator_id
  has_many :annotations
  has_one :profile, :dependent => :destroy

  belongs_to :role, :class_name => "UserRole", :foreign_key => :role_id

  validates_presence_of     :login, :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  before_save :encrypt_password


  after_create :create_profile

  def create_profile
    self.profile = Profile.new
    self.save
  end

  # Returns a boolean value indicating whether or not this user
  # can act as the role specified.  The user is considered to be
  # able to do this if they have an access level <= the level of
  # the role specified.  This is used for many system permission
  # functions instead of reading the integer representing the integer
  # directly, so that UserRoles can be added later without changing
  # code in all areas.
  def can_act_as?(role_string)
    role = UserRole.find_by_name(role_string)

    if role.nil?
      return false
    end

    return self.role.level <= role.level
  end

  def full_name
    if self.profile.first_name.nil? ||
        self.profile.last_name.nil?
      return self.login
    else
      return self.profile.first_name + " " + self.profile.last_name
    end
  end

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation

  acts_as_state_machine :initial => :pending
  state :passive

  state :pending
  state :active,  :enter => :do_activate
  state :suspended
  state :deleted, :enter => :do_delete

  event :register do
    transitions :from => :passive, :to => :pending, :guard => Proc.new {|u| !(u.crypted_password.blank? && u.password.blank?) }
  end

  event :activate do
    transitions :from => :pending, :to => :active
  end

  event :suspend do
    transitions :from => [:passive, :pending, :active], :to => :suspended
  end

  event :delete do
    transitions :from => [:passive, :pending, :active, :suspended], :to => :deleted
  end

  event :unsuspend do
    transitions :from => :suspended, :to => :active,  :guard => Proc.new {|u| !u.activated_at.blank? }
    transitions :from => :suspended, :to => :pending, :guard => Proc.new {|u| !u.activation_code.blank? }
    transitions :from => :suspended, :to => :passive
  end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_in_state :first, :active, :conditions => {:login => login} # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  def forgot_password
    @forgotten_password = true
    self.make_password_reset_code
    UserMailer.deliver_forgot_password(self)
  end
  
  def reset_password
    # First update the password_reset_code before setting the
    # reset_password flag to avoid duplicate email notifications.
    update_attribute(:password_reset_code, nil)
    @reset_password = true
  end  

  #used in user_observer
  def recently_forgot_password?
    @forgotten_password
  end
  
  def recently_reset_password?
    @reset_password
  end
  
  def self.find_for_forget(email)
    find :first, :conditions => 
      ['email = ? and activation_code IS NULL', email]
  end

  # Returns an array of the content items belonging to this
  # user.
  def cloned_content_items
    conditions = 'parent_id != \'NULL\' AND ' +
      'creator_id = ?'

    return ContentItem.find( :all, 
                             :conditions => [ conditions,
                                              self.id ]
                             )
  end
  
  protected
    # before filter
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end

    def password_required?
      crypted_password.blank? || !password.blank?
    end


    def do_delete
      self.deleted_at = Time.now.utc
    end

    def do_activate
      self.activated_at = Time.now.utc
      self.deleted_at = self.activation_code = nil
    end

    def make_password_reset_code
      self.password_reset_code = 
        Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
      self.save
    end
end
