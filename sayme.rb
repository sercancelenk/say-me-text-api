# encoding: UTF-8
require 'json'
require 'sinatra'
require 'data_mapper'
require 'dm-migrations'
require 'dm-validations'
require 'json'
require 'ensure/encoding'
require 'time'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require 'sinatra/partial'
require 'warden'
require 'bcrypt'
require 'fastimage'
require 'sinatra/formkeeper'
require 'pony'
require 'sinatra/captcha'
require 'rufus-scheduler'
require 'sinatra/kittens'


SITE_TITLE = "Say Me Text"
SITE_DESCRIPTION = "ask me "


# use Rack::Session::Cookie, secret: "IdoNotHaveAnySecret"




class SayMeApp < Sinatra::Application
  register Sinatra::FormKeeper
  set :threaded, true
  # use Rack::Session::Cookie, :key => 'rack.session',
  #     :domain => 'blahblahblah',
  #     :path => '/',
  #     :expire_after => 10000,#7*24*60*60, # 7 days (seconds)
  #     :secret => 'Sma@@13?>000blahblah'

  enable :sessions
  # set :sessions, :expire_after => 100

  set :session_secret, "Sma@@13?>000blahblah"


  use Warden::Manager do |config|
    # Tell Warden how to save our User info into a session.
    # Sessions can only take strings, not Ruby code, we'll store
    # the User's `id`
    config.serialize_into_session{|user| user.id }
    # Now tell Warden how to take what we've stored in the session
    # and get a User from that information.
    config.serialize_from_session{|id| Account.get(id) }
    config.scope_defaults :default,
                          # "strategies" is an array of named methods with which to
                          # attempt authentication. We have to define this later.
                          strategies: [:password],
                          # The action is a route to send the user to when
                          # warden.authenticate! returns a false answer. We'll show
                          # this route below.
                          action: 'auth/unauthenticated'
    # When a user tries to log in and cannot, this specifies the
    # app to send the user to.
    config.failure_app = self
  end
  Warden::Manager.before_failure do |env,opts|
    env['REQUEST_METHOD'] = 'POST'
  end
  Warden::Strategies.add(:password) do
    def valid?
      params['user'] && params['user']['email'] && params['user']['password']
    end
    def authenticate!
      user = Account.first(:email => params['user']['email'], :status=>true)
      if user.nil?
        throw(:warden, message: "The username you entered does not exist.")
      elsif user.authenticate(params['user']['password'])
        success!(user)
      else
        throw(:warden, message: "The username and password combination ")
      end
    end
    def authenticate2!
      user = Account.first(:email => params['user']['email'], :status=>true)
      if user.nil?
        throw(:warden, message: "The username you entered does not exist.")
      elsif user.authenticate(params['user']['password'])
        success!(user)
      else
        throw(:warden, message: "The username and password combination ")
      end
    end
  end


  # add controllers and views
  configure do
    root = File.expand_path(File.dirname(__FILE__))
    set :views, File.join(root, 'views')
    set :static, true
    set :public_folder, File.dirname(__FILE__) + '/public'

    register Sinatra::Kittens
  end
  configure :development do
    enable :logging, :dump_errors, :raise_errors
    # disable :show_exceptions
    # DataMapper::Logger.new(STDOUT, :debug, '[DataMapper] ')
    DataMapper::Model.raise_on_save_failure = false
    DataMapper::Property::String.length(255)
    DataMapper::Property::Boolean.allow_nil(false)
    DataMapper.setup(
        :default,
        'mysql://root:root12@localhost/saymedb'
    )
  end
  configure :production do
    DataMapper.setup(
        :default,
        'mysql://root:root12@localhost/saymedb'
    )
  end

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html
  end
end

require './models/init'
require './helpers/init'
require './routes/init'

# JOBS
# require './scheduling/init'

DataMapper.finalize