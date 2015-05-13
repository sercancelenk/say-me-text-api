class Account
  include DataMapper::Resource
  include BCrypt

  property :id, Serial, key: true
  property :email, String, length: 128, :format => :email_address, :unique => true, :required => true,
           :messages => {
               :presence  => "We need your email address.",
               :is_unique => "We already have that email.",
               :format    => "Doesn't look like an email address to me ..."
           }
  property :password, BCryptHash,
           :messages => {
               :presence  => "You need password."
           }
  property :namesurname, String, length: 128
  property :phone, String, length: 128
  property :zipcode, String, length: 255
  property :country, String, length: 128
  property :city, String, length: 128
  property :status, Boolean
  property :account_type, Text
  property :created_date, Date

  has n, :addresy
  has n, :payment
  has n, :request_action
  has n, :response_action
  has n, :active_account


  def authenticate(attempted_password)
    # The BCrypt class, which `self.password` is an instance of, has `==` defined to compare a
    # test plain text string to the encrypted string and converts `attempted_password` to a BCrypt
    # for the comparison.
    #
    # But don't take my word for it, check out the source: https://github.com/codahale/bcrypt-ruby/blob/master/lib/bcrypt/password.rb#L64-L67
    if self.password == attempted_password
      true
    else
      false
    end
  end
end

