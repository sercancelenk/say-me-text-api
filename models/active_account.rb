class ActiveAccount
  include DataMapper::Resource

  property :id, Serial, key: true
  property :atime, Time

  belongs_to :account

end