class RequestAction
  include DataMapper::Resource

  property :id, Serial, key: true
  belongs_to :account
  belongs_to :resolver, 'Account', :key => true
  property :incoming_service_token, Text
  property :requesting_image, Text
  property :requesting_time, Time, :message=>"Yanlis format"
  property :request_status, Text
  property :request_type, Text
  has 1, :response_action
end