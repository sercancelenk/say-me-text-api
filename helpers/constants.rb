# encoding: UTF-8
require 'sinatra/base'

module Sinatra
  module ApiEnums
    module AccountType
      ADMIN="ADMIN"
      RESOLVER="RESOLVER"
      CLIENT="CLIENT"
    end
    module RequestStatus
      PENDING="PENDING"
      RESPONDED="RESPONDED"
      ERROR="ERROR"
      NOTRESPONDED="NOTRESPONDED"
    end
    module RequestType
      IMAGE="IMAGEREQUEST"
      CREDIT="CREDITREQUEST"
      BACKRETURN="BACKRETURN"
    end

    module PaymentStatus
      SUCCESS="SUCCESS"
      FAIL="FAIL"
    end

    module ServiceStatus
      ACTIVE="ACTIVE"
      PASSIVE="PASSIVE"
    end

    module AccountStatus
      ACTIVE="ACTIVE"
      PASSIVE="PASSIVE"
      BANNED="BANNED"
    end
  end
  module Messages
    module Error
      GENERIC_ERROR = "An error is occured!"
      IMAGE_TYPE_ERROR = "Image type not accepted. Valid image types : png, jpg, jpeg, gif"
    end
    module Message
      BACK_RETURN_RESPONSE_MESSAGE = "We will be back return soon. Thanks."
    end
  end
  SayMeApp.helpers ApiEnums
  SayMeApp.helpers Messages
end