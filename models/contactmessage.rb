class ContactMessage
  include DataMapper::Resource

  property :id, Serial, key: true
  property :namesurname, Text, :required => true
  property :email, Text, :required => true
  property :message, Text, :required => true
  property :notified, Boolean, :default => false
end