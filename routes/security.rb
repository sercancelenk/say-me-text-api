class SayMeApp < Sinatra::Application

  login_page = lambda do
    erb :home, :layout=>:"layout/layout"
  end
  login_action = lambda do
    env['warden'].authenticate!
    # flash[:success] = env['warden'].message
    if session[:return_to].nil?
      redirect '/'
    else
      redirect session[:return_to]
    end
  end
  logout_action = lambda do
    env['warden'].raw_session.inspect
    env['warden'].logout
    flash[:success] = 'Successfully logged out'
    redirect '/'
  end
  is_authenticated = lambda do
    session[:return_to] = env['warden.options'][:attempted_path] if session[:return_to].nil?
    # Set the error and use a fallback if the message is not defined
    flash[:error] = env['warden.options'][:message] || "You must log in"
    redirect '/auth/login'
  end

  get '/auth/login', &login_page
  post '/auth/login', &login_action
  get '/auth/logout', &logout_action
  post '/auth/unauthenticated', &is_authenticated

end