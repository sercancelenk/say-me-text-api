require 'sinatra/captcha'

class SayMeApp < Sinatra::Application
  queryforweb = QueryForWeb.new

  before do
    headers 'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST'],
            'Access-Control-Allow-Headers' => 'Content-Type'

    @requestActions = queryforweb.getResponseRequestCountsBy 60, env['warden'].user
    @apiInfo = {}
    @apiInfo['respondedCount'] = @requestActions.count
  end

  home_page = lambda do

    erb :home, locals: {appinfo: @apiInfo}, :layout=>:"layout/layout"
    # val = 10
    # thr = Thread.new {
    #   puts "Whats the big deal"
    #   x = 1
    #   while true
    #     puts "sorgu yapildi " << x.to_s
    #     x += 1
    #     val = x
    #     sleep 1
    #     if x > 10
    #       break
    #     end
    #   end
    #
    # }
    # thr.join

    # constant = Constant.new
    # constant.nkey = "response_total_time"
    # constant.nvalue = "60"
    # constant.status = true
    # constant.save


    # serviceType = ServiceType.new
    # serviceType.name = "10K"
    # serviceType.description="Image solving service"
    # serviceType.price = 12
    # serviceType.created_date = Time.now
    # serviceType.totalcredit = 12000
    # serviceType.save
    #
    # account = Account.new
    # account.email="sercancelenk@gmail.com"
    # account.password ="123456"
    # account.namesurname="Sercan CELENK"
    # account.phone="5302008502"
    # account.zipcode="34880"
    # account.country="TURKEY"
    # account.city="ISTANBUL"
    # account.status=true
    # account.created_date = Time.now
    # if account.save
    #   payment = Payment.new
    #   payment.servicetoken = "srcnclnk5K"
    #   payment.paymentstatus = "SUCCESS"
    #   payment.service_type = serviceType
    #   payment.account = account
    #   payment.remainingcredit = serviceType.totalcredit
    #   payment.created_date = Time.now
    #
    #   payment.save
    # else
    #   account.errors.each do |e|
    #     puts e
    #   end
    # end



    # account = Account.first(:email=>"sercancelenk@gmail.com")
    # service = ServiceType.first(:name=>"5K")




    # payment
    # property :servicetoken, Text
    # property :paymentstatus, Text
    # property :remainingcredit, Integer
    # property :created_date, Time

    # payment = Payment.all(:account=>account)
    #
    # pservicetype = payment.service_type




    # format_response(val, request.accept)

  end
  faq_page = lambda do
    erb :"shared_web_pages/faq", :layout => :"layout/layout"
  end
  services_page = lambda do
    erb :"shared_web_pages/buyservice", :layout => :"layout/layout"
  end
  api_page = lambda do
    erb :"shared_web_pages/api", :layout => :"layout/layout"
  end
  contact_page = lambda do
    erb :"shared_web_pages/contact", :layout => :"layout/layout"
  end
  register_page = lambda do
    erb :"shared_web_pages/register", :layout => :"layout/layout"
  end
  resolve_captcha_page = lambda do
    env['warden'].authenticate!
    # flash[:success] = env['warden'].message
    if env['warden'].user.account_type.eql?AccountType::RESOLVER
      erb :resolveCaptcha, :layout => :"layout/resolver_layout"
    else
      redirect '/'
    end

  end
  profile_page = lambda do
    if env['warden'].user.nil?
      env['warden'].authenticate!
    end
    @user = env['warden'].user
    if @user.account_type.eql?AccountType::RESOLVER
      erb :"shared_web_pages/profile", :layout=>:"layout/resolver_layout"
    else
      erb :"shared_web_pages/profile", :layout=>:"layout/layout"
    end

  end

  register_action = lambda do
       form do
         filters :strip, :downcase
         field :namesurname, :present => true, :length => 4..20
         field :email, :present => true
         field :pass1, :present => true, :length => 6..12
         field :pass2, :present => true, :length => 6..12
         same :same_password, [:pass1, :pass2]
       end
       if form.failed?
         output = erb :"shared_web_pages/register"
         fill_in_form(output)
       else
         unless captcha_pass? params[:chunky], params[:bacon]
           flash[:error] = "Please check captcha code!"
           output = erb :"shared_web_pages/register"
           fill_in_form(output)
         else
           reqHash = request.env["rack.request.form_hash"]
           email = StringOperations.uri_unescape(reqHash["email"])
           namesurname = StringOperations.uri_unescape(reqHash["namesurname"])
           pass = StringOperations.uri_unescape(reqHash["pass1"])
           account = Account.new
           account.status = false
           account.created_date = DateOperations.nowtime
           account.namesurname = namesurname
           account.password = pass
           account.account_type = AccountType::CLIENT
           account.email = email

           if account.save
             mailBody = ""
             mailBody << "<p>"
             mailBody << "Welcome to SayMeCaptcha, If you activate your account, please click the following link"
             mailBody << "<br>"
             returnAddress = 'http://localhost:9292/account/activate/sd=' << (account.id.to_i * 5).to_s
             mailBody << "<a href='" << returnAddress << "'>Activate</a>"
             mailBody << "</p>"
             Mail.sendMail email, "SayMeCaptcha Account Verify", mailBody

             flash[:error] = "Account created successfully. Please confirm your account from email."
             redirect "/register"
           else
             errors = ""
             account.errors.each do |e|
               e.each do |m|
                 errors << m << ","
               end
             end


             flash[:error] = errors
             redirect '/register'
           end
         end
       end


  end
  account_activate_action = lambda do
      activateId = StringOperations.uri_unescape(params[:sd]).to_i
      email = StringOperations.uri_unescape(params[:m])
      unless email.nil? and activateId.nil?
        acc = Account.first(:email=>email)
        erb :"shared_web_pages/accok"
      else
        halt 401, 'go away!'
      end

  end

  api_info_action = lambda do
    # env['warden'].authenticate!

    if params[:tr].nil?
      return format_response("No record", request.accept)
    end
    @requestActions = queryforweb.getResponseRequestCountsBy params[:tr].to_i, env['warden'].user
    @apiInfo = {}
    @apiInfo['respondedCount'] = @requestActions.count

    return format_response(@apiInfo, request.accept)
  end
  request_statistics_action = lambda do
    # env['warden'].authenticate!

    if params[:tr].nil?
      return format_response("No record", request.accept)
    end
    puts "BLAHBLAHBLAH " << env['warden'].user.namesurname
    @acts = queryforweb.getRequestStatisticsBy (60 * 60 * 24 * 7), env['warden'].user

    return format_response(@acts, request.accept)
  end
  email_control_action = lambda do
    unless params[:m].nil?
      acc = Account.first(:email=>StringOperations.uri_unescape(params[:m]))
      unless acc.nil?
        return format_response(true, request.accept)
      end
    end
    return format_response(false, request.accept)
  end

  incoming_requests_by_resolver = lambda do
    unless env['warden'].user.account_type.eql?AccountType::RESOLVER
      env['warden'].authenticate!
    end
    puts env['warden'].user.id
    timeRange = DateOperations.nowtimeobject-(60 * 60 * 24 * 7)
    pendingRequests = RequestAction.all(:requesting_time.gt => timeRange,
                                        :request_status => RequestStatus::PENDING,
                                        :request_type => RequestType::IMAGE,
                                        :resolver => env['warden'].user,
                                            :order => [ :requesting_time.desc ])
    unless pendingRequests.nil? and not pendingRequests.empty?
      return format_response(pendingRequests, request.accept)
    end
    return format_response("No requests", request.accept)

  end
  resolve_captcha_action = lambda do
    # return format_response(request.env, request.accept)
    env['warden'].authenticate!
    # flash[:success] = env['warden'].message
    if env['warden'].user.account_type.eql?AccountType::RESOLVER
      # reqHash = request.body.read
      request.body.rewind
      reqHash = JSON.parse request.body.read
      if reqHash.nil? or reqHash.empty? or reqHash["rt"].nil? or reqHash["rt"].eql?"" or reqHash["raid"].nil? or reqHash["raid"].eql?""
        timeRange = DateOperations.nowtimeobject-(60 * 60 * 24 * 7)
        pendingRequests = RequestAction.all(:requesting_time.gt => timeRange,
                                            :request_status => RequestStatus::PENDING,
                                            :request_type => RequestType::IMAGE,
                                            :order => [ :requesting_time.desc ])
        return format_response(pendingRequests, request.accept)
      else
        rt = StringOperations.parse(reqHash["rt"].to_s)
        raid = StringOperations.parse(reqHash["raid"].to_s)
        requestAction = RequestAction.get(raid.to_i)

        responseAction = ResponseAction.new
        responseAction.request_id = raid
        responseAction.response_text = rt
        responseAction.valid = true
        responseAction.error = false
        responseAction.error_message = ""
        responseAction.success_message = "Response successeded"
        responseAction.created_date = DateOperations.nowtimeobject
        responseAction.account = env['warden'].user
        responseAction.request_action = requestAction
        core.savePojo responseAction

        requestAction.request_status = RequestStatus::RESPONDED
        core.savePojo requestAction


        timeRange = DateOperations.nowtimeobject-(60 * 60 * 24 * 7)
        pendingRequests = RequestAction.all(:requesting_time.gt => timeRange,
                                            :request_status => RequestStatus::PENDING,
                                            :request_type => RequestType::IMAGE,
                                            :order => [ :requesting_time.desc ])
        return format_response(pendingRequests, request.accept)

      end


    end
    return format_response("No requests", request.accept)
  end
  i_am_active_action = lambda do
    env['warden'].authenticate!
    # flash[:success] = env['warden'].message
    if env['warden'].user.account_type.eql?AccountType::RESOLVER
      isActiveAccount = ActiveAccount.first(:account=>env['warden'].user)
      if isActiveAccount.nil?
        activeAccount = ActiveAccount.new
        activeAccount.account = env['warden'].user
        activeAccount.atime = DateOperations.nowtime
        activeAccount.save
      else
        isActiveAccount.atime = DateOperations.nowtime
        isActiveAccount.save
      end

      return format_response(true, request.accept)
    end
  end


  get '/', &home_page
  get '/api', &api_page
  get '/contact', &contact_page
  get '/services', &services_page
  get '/faq', &faq_page
  get '/register', &register_page
  get '/profile', &profile_page

  post '/register', &register_action
  get '/account/activate', &account_activate_action
  get '/resolveCaptcha', &resolve_captcha_page
  get '/apinfo/:tr', &api_info_action
  get '/reqstats/:tr', &request_statistics_action
  get '/mc', &email_control_action
  get '/reqs', &incoming_requests_by_resolver
  post '/resolverAction', &resolve_captcha_action
  post '/iamactive', &i_am_active_action

end