class SayMeApp < Sinatra::Application
  credentials = Credentials.new
  core = ApiCore.new
  before do
    headers 'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST'],
            'Access-Control-Allow-Headers' => 'Content-Type'
  end

  receive_request = lambda do

    content_type :json
    requestAction = nil
    response = nil
    begin

        reqHash = request.env["rack.request.form_hash"]
        fileHash = (request.env["rack.request.form_hash"]["saymefi"])
        usr = StringOperations.uri_unescape(reqHash["usr"])
        pss = StringOperations.uri_unescape(reqHash["pss"])
        st = StringOperations.uri_unescape(reqHash["st"])
        file = fileHash[:tempfile]
        fileName = StringOperations.uri_unescape fileHash[:filename]
        fileType = StringOperations.uri_unescape fileHash[:type]
        head = StringOperations.uri_unescape fileHash[:head]
        # head: "Content-Disposition: form-data; name="saymefi"; filename="facebook.png" Content-Type: image/png "

        response = credentials.validateParamsForAccountWithFile usr, pss, st, file, fileType, head

        if response.valid
          filePostfix = fileType.gsub! 'image/', ''
          # Credentials is true, and we are saving incoming image
          requestTime = DateOperations.nowtime
          timeRange = DateOperations.nowtimeobject - (61)
          constant = Constant.first(:nkey => "base_upload_directory")
          uploadDirectory = constant.nvalue
          tmpFileName = StringOperations.parse uploadDirectory << requestTime.to_s << "_" << fileName
          # File is writing
          File.write("public/" << tmpFileName, fileHash[:tempfile].read)
          imageType = FastImage.type("public/" << tmpFileName)
          if imageType.eql? :"png" or imageType.eql? :"jpg" or imageType.eql? :"jpeg" or imageType.eql? :"gif"
            requestAction = RequestAction.new
            requestAction.account = response.data.account
            requestAction.incoming_service_token = st
            requestAction.requesting_image = tmpFileName
            requestAction.requesting_time = requestTime
            requestAction.request_status = RequestStatus::PENDING
            requestAction.request_type = RequestType::IMAGE
            activeAccount = ActiveAccount.first(:atime.gt => timeRange, :order => [ :atime.desc ])
            requestAction.resolver=activeAccount.account

            if core.savePojo requestAction
              begin
                  Thread.abort_on_exception=true
                  constant = Constant.first(:nkey => "response_total_time")
                  response_total_time = constant.nvalue.to_i
                  responseAction = nil
                  responseWaitingThread = Thread.new {
                    timeBySecond = 1
                    while true
                      responseAction = ResponseAction.first(:request_id => requestAction.id, :request_action => requestAction, :account => response.data.account)
                      timeBySecond += 1

                      unless responseAction.nil?
                        unless responseAction.id<=0
                          break
                        end
                      end
                      sleep 1
                      if timeBySecond > response_total_time
                        break
                      end
                    end
                  }
                  responseWaitingThread.join
              rescue Exception => e
                response.data = nil
                response.result_id = 0
                response.valid = false
                response.error = Error::GENERIC_ERROR

                requestAction.request_status = RequestStatus::ERROR
                requestAction.save

                return format_response(response, request.accept)
              end

              #:result_id, :data, :valid, :duration, :error
              if responseAction.nil? or responseAction.id <= 0
                # Resolver cevaplamadi
                # Request action statusunru guncelliyoruz
                requestAction.request_status = RequestStatus::NOTRESPONDED
                requestAction.save

                response.data = nil
                response.result_id = 0
                response.valid = false
                response.error = Error::GENERIC_ERROR
              else
                # Resolver cevapladi ve userin kredisinden dusuyoruz..
                vremainingcredit = response.data.remainingcredit.to_i
                response.data.remainingcredit = vremainingcredit - 1
                if core.savePojo response.data
                  # Request action statusunu guncelliyoruz
                  requestAction.request_status = RequestStatus::RESPONDED
                  if core.savePojo requestAction
                    # Clienta gonderilecek olan datayi yazioruz.
                    response.data = responseAction.response_text
                    response.result_id = requestAction.id
                    response.valid = true
                    response.error = nil
                  end
                end
              end
            else
              response.data = nil
              response.result_id = 0
              response.valid = false
              response.error = Error::GENERIC_ERROR
            end
          else
            #FIXED:burada image tipi yanlis oldugu icin hata verilecek
            response.data = nil
            response.result_id = 0
            response.valid = false
            response.error = Error::IMAGE_TYPE_ERROR
          end

        else
            #FIXED: burada response valid gelmedigi icin uyari verilecek
        end

        return format_response(response, request.accept)
    rescue Exception => e
      if response.nil?
        response = SMResponse.new
      end
      response.data = nil
      response.result_id = 0
      response.valid = false
      response.error = e#Error::GENERIC_ERROR

      unless requestAction.nil?
        requestAction.request_status = RequestStatus::ERROR
        requestAction.save
      end
      return format_response(response, request.accept)
    end

    # return JSON.pretty_generate(request.env)

    # {
    #     "filename": "facebook.png",
    #     "type": "image/png",
    #     "name": "fileUpload",
    #     "tempfile": "#<File:0x007f9dcafa2bb0>",
    #     "head": "Content-Disposition: form-data; name=\"fileUpload\"; filename=\"facebook.png\"\r\nContent-Type: image/png\r\n"
    # }

  end
  receive_credit_info_request = lambda do
    content_type :json

    begin
        # request time is saving
        requestTime = DateOperations.nowtime
        reqHash = request.env["rack.request.form_hash"]
        usr = StringOperations.uri_unescape(reqHash["usr"])
        pss = StringOperations.uri_unescape(reqHash["pss"])
        st = StringOperations.uri_unescape(reqHash["st"])
        # head: "Content-Disposition: form-data; name="saymefi"; filename="facebook.png" Content-Type: image/png "

        response = credentials.validateParamsForAccount usr, pss, st

        if response.valid
          # Incoming request saving
          creditRequestAction = RequestAction.new
          creditRequestAction.account = response.data.account
          creditRequestAction.incoming_service_token = st
          creditRequestAction.requesting_image = nil
          creditRequestAction.requesting_time = requestTime
          creditRequestAction.request_status = RequestStatus::RESPONDED
          creditRequestAction.request_type = RequestType::CREDIT
          if core.savePojo creditRequestAction
            creditinfo = response.data
            response.data = creditinfo.remainingcredit
          end
        end
        return format_response(response, request.accept)
    rescue Exception => e
      if response.nil?
        response = SMResponse.new
      end
      response.data = nil
      response.result_id = 0
      response.valid = false
      response.error = Error::GENERIC_ERROR

      creditRequestAction.request_status = RequestStatus::ERROR
      creditRequestAction.save
      return format_response(response, request.accept)
    end
  end
  receive_back_return = lambda do
    content_type :json

    begin
      # request time is saving
      requestTime = DateOperations.nowtime
      reqHash = request.env["rack.request.form_hash"]
      usr = StringOperations.uri_unescape(reqHash["usr"])
      pss = StringOperations.uri_unescape(reqHash["pss"])
      rai = StringOperations.uri_unescape(reqHash["rai"])
      st = StringOperations.uri_unescape(reqHash["st"])
      # head: "Content-Disposition: form-data; name="saymefi"; filename="facebook.png" Content-Type: image/png "

      response = credentials.validateParamsForAccount usr, pss, st

      if response.valid
        # Incoming request saving
        backReturn = BackReturn.new
        backReturn.account = response.data.account
        backReturn.request_action_id = rai
        backReturn.request_type = RequestType::BACKRETURN
        if core.savePojo backReturn
          response.data = Message::BACK_RETURN_RESPONSE_MESSAGE
        end
      end
      return format_response(response, request.accept)
    rescue Exception => e
      if response.nil?
        response = SMResponse.new
      end
      response.data = nil
      response.result_id = 0
      response.valid = false
      response.error = Error::GENERIC_ERROR

      creditRequestAction.request_status = RequestStatus::ERROR
      creditRequestAction.save
      return format_response(response, request.accept)
    end

  end

  post '/sm', &receive_request
  post '/ci', &receive_credit_info_request
  post '/br', &receive_back_return
end