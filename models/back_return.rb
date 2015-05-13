class BackReturn
  include DataMapper::Resource

  property :id, Serial, key: true
  property :request_action_id, String
  property :request_type, Text
  belongs_to :account

end