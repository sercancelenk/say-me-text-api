# encoding: UTF-8
require 'sinatra/base'

module Sinatra

  module Api
    class Persistence
      def _findAccountBy usr, pass
        account = Account.first(:email => Utility::StringOperations.uri_unescape(usr))
        isOk = false
        unless account.nil?
          isOk = account.authenticate (Utility::StringOperations.uri_unescape(pass))
        end
        return account if isOk
      end
      def savePojo pojo
        begin
          if pojo.save
             return true
          else
            errors = []
            pojo.errors.each do |e|
              errors.push e
            end
            return errors
          end
        rescue Exception => e
          puts e
        end

      end
    end

    class ApiCore < Persistence
      def _loadCreditInfoBy usr, pass, service_token
        account = _findAccountBy usr, pass

        unless account.nil?
          payment = Payment.first(:account => account, :servicetoken=>service_token)
          return payment
        else
          return nil
        end
      end

    end

    class Credentials < ApiCore

      def validateParamsForAccountWithFile usr, pass, service_token, file, fileType, head
        if fileType.nil? or fileType.empty? or fileType.gsub(/\s+/, "").eql?''
          resp.error = "Content type error"
          resp.valid = false
          return resp
        end
        resp = SMResponse.new
        if usr.nil? or usr.empty? or pass.nil? or pass.empty? or service_token.nil?  or service_token.empty?
          resp.error = "Username or password must not be null"
          resp.valid = false
        elsif file.nil?
          resp.valid = false
          resp.error = "Image file not found"
        else
          usr = Utility::StringOperations.uri_unescape(usr)
          pss = Utility::StringOperations.uri_unescape(pass)
          st = Utility::StringOperations.uri_unescape(service_token)

          account = _findAccountBy usr, pss
          if account.nil?
            resp.valid = false
            resp.error = "Account not found"
            resp.data = nil
          else
            creditInfo = _loadCreditInfoBy(usr, pss, st)
            if creditInfo.nil? or creditInfo.remainingcredit <= 0
              resp.valid = false
              resp.error = "No credit for request"
              resp.data = nil
            else
              resp.valid = true
              resp.data = creditInfo
            end
          end

        end
        return resp

      end

      def validateParamsForAccount usr, pass, service_token
        resp = SMResponse.new
        if usr.nil? or usr.empty? or pass.nil? or pass.empty? or service_token.nil?  or service_token.empty?
          resp.error = "Username or password must not be null"
          resp.valid = false
        else
          usr = Utility::StringOperations.uri_unescape(usr)
          pss = Utility::StringOperations.uri_unescape(pass)
          st = Utility::StringOperations.uri_unescape(service_token)

          account = _findAccountBy usr, pss
          if account.nil?
            resp.valid = false
            resp.error = "Account not found"
            resp.data = nil
          else
            creditInfo = _loadCreditInfoBy(usr, pss, st)
            resp.valid = true
            resp.data = creditInfo
          end

        end
        return resp

      end

    end

    class SMResponse
      attr_accessor :result_id, :data, :valid, :duration, :error
      def self.json_create(o)
        new(*o['data'])
      end

      def to_json(*a)
        { 'api' => "SayMeApp v1.0", 'data' => {"result_id"=>result_id, "data" => data, "valid"=>valid, "duration"=>duration, "error"=>error} }.to_json(*a)
      end
    end
  end
  module Web

    class QueryForWeb
      def getResponseRequestCountsBy timeRange, user
        createdDate = Utility::DateOperations.nowtimeobject-timeRange.to_i
        respondedRequests = RequestAction.all(:requesting_time.gt => createdDate,
                                              :request_status => ApiEnums::RequestStatus::RESPONDED,
                                              :resolver => user,
                                              :order => [ :requesting_time.desc ])
        return respondedRequests unless respondedRequests.nil?
      end
      def getRequestActions timeRange, user
        createdDate = Utility::DateOperations.nowtimeobject-timeRange.to_i
        respondedRequests = RequestAction.all(:requesting_time.gt => createdDate,
                                              :resolver => user,
                                              :order => [ :requesting_time.desc ])
        return respondedRequests unless respondedRequests.nil?
      end
      def getResponseActions timeRange, user
        createdDate = Utility::DateOperations.nowtimeobject-timeRange.to_i
        respondedRequests = ResponseAction.all(:created_date.gt => createdDate,
                                               :resolver => user,
                                               :order => [ :createdDate.desc ])
        return respondedRequests unless respondedRequests.nil?
      end
      def getRequestStatisticsBy timeRange, user
        stat  = RequestAction.aggregate(:request_status,:request_status.count, :conditions => [:resolver => user])
        result = {}
        if stat.nil?
        else
          stat.each do |k,v|
            result[k] = v
          end
          puts result.to_json
          return result
        end
      end

      def passwordReset

      end

      def buyService

      end

      def getBackReturns

      end
      def getAccounts

      end
      def getConstants

      end

      def getPayments

      end
    end

    class WebCore

    end

  end
  SayMeApp.helpers Web
  SayMeApp.helpers Api
end