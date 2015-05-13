# encoding: UTF-8
require 'sinatra/base'
require "unicode_utils/nfc"
require 'pony'

module Sinatra

  module ResponseFormat
    def format_response(data, accept)
      accept.each do |type|
        return data.to_xml  if type.downcase.eql? 'text/xml'
        return data.to_json if type.downcase.eql? 'application/json'
        return data.to_yaml if type.downcase.eql? 'text/x-yaml'
        return data.to_csv  if type.downcase.eql? 'text/csv'
        return data.to_json
      end
    end
  end

  module ApplicationHelper
    def show_error_message(message="Gecerli bir deger girmelisiniz")
      ['<small class="error">',message,'</small>'].join.html_safe
    end
    def flash_class(type)
      {notice: 'alert-success', alert: 'alert-info', error:'alert-warning'}[type]
    end

  end

  module Utility

    class DateOperations
      def self.iso8601_to_mysql_datetime(date)
        DateTime.parse(date).to_time.strftime("%F %T")
      end
      def self.nowtime
        Time.now.strftime("%F %T")
            #.strftime("%d-%m-%Y %H:%M")
      end
      def self.nowtimeobject
        Time.now
      end
    end
    class StringOperations

      def self.parse(input)
        if input.nil? or input.strip.length == 0
          return ''
        end
        input = normalize(input)
        input = clearMoreBlankChars(input)
        input = input.downcase
        input = input.gsub(" ","-")

        return input
      end
      def self.uri_encode txt
        return URI.encode(txt)
      end
      def self.uri_decode txt
        return URI.decode(txt)
      end
      def self.uri_unescape txt
        return URI.unescape txt
      end
      def self.uri_escape txt
        return URI.escape txt
      end

      def self.normalize(input)
        return UnicodeUtils.nfc(input).gsub("/\p{ASCII}/","")
      end

      def self.clearMoreBlankChars(input)
        if input.nil? or self.trim(input).length == 0
          return ""
        end
        return input.gsub(/\s+/, ' ').strip
      end

      def self.cleanNotUrlChars(input)
        unless !input.nil? or !self.trim(input).length == 0
          return ""
        end


        input = clearMoreBlankChars(input)

        input = input.force_encoding("UTF-8").gsub("İ".force_encoding("UTF-8"),"i")
        input = input.gsub("I", "i")
        input = input.gsub("ı", "i")
        input = input.gsub(".", "")
        input = input.gsub("\"", "")
        input = input.gsub("ş", "s")
        input = input.gsub("Ş", "s")
        input = input.gsub("ü", "u")
        input = input.gsub("Ü", "u")
        input = input.gsub("ğ", "g")
        input = input.gsub("Ğ", "g")
        input = input.gsub("ö", "o")
        input = input.gsub("Ö", "o")
        input = input.gsub("ç", "c")
        input = input.gsub("Ç", "c")
        input = input.gsub("é", "e")
        input = input.gsub("è", "e")
        input = input.gsub("&", "-")
        input = input.gsub("@", "")
        input = input.gsub("?", "")
        input = input.gsub("+", " ")
        input = input.gsub("*", "")
        input = input.gsub(" - ", "-")
        input = input.gsub("''", "")
        input = input.gsub("`", "")
        input = input.gsub("´", "")
        input = input.gsub("'", "")
        input = input.gsub("’", "")
        input = input.gsub("‘", "")
        input = input.gsub("(", " ")
        input = input.gsub(")", " ")
        input = input.gsub("!", "")
        input = input.gsub("/", "")
        input = input.gsub("%", " yuzde ")
        input = input.gsub(":", "")
        input = input.gsub("®", "")
        input = input.gsub("©", "")
        input = input.gsub(",", " ")
        input = input.gsub("_", "-")
        input = input.gsub("ã", "a")
        input = input.gsub("æ", "ae")
        input = input.gsub("\\","")
        input = input.gsub(" ","-").downcase

        input = clearMoreBlankChars(input)

        return input

      end

      def self.trim(input)
        if input.nil? or input.length <= 0
          return ""
        end

        if input.split.size == 1
          return input.split
        else
          arr = input.split

          result = ""
          index = 0

          arr.each do |x|
            tmp = x
            if index == 0
              result = tmp
              index = index + 1
            else
              result = result + " " + tmp
            end
          end
          return result
        end

      end
    end

    class Mail
      def initialize

      end
      def self.sendMail to, subject, body
        # Mail options
        @options = {
            :to => to,
            :subject=> subject,
            :html_body => body,
            :via => :smtp,
            :via_options => {
                :address              => 'mail.istcape.com',
                :port                 => '587',
                :enable_starttls_auto => true,
                :user_name            => 'info@istcape.com',
                :password             => '123456',
                :authentication       => :plain, # :plain, :login, :cram_md5, no auth by default
                :domain               => "localhost.localdomain"
            },
            :headers => { "Reply-To" => to }
        }
        Pony.mail(@options)

      end
    end
  end

  SayMeApp.helpers ResponseFormat
  SayMeApp.helpers ApplicationHelper
  SayMeApp.helpers Utility
end