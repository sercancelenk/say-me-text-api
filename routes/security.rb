class SayMeApp < Sinatra::Application
  get '/auth/login' do
    erb :home, :layout=>:"layout/layout"
  end
  post '/auth/login' do
    env['warden'].authenticate!
    # flash[:success] = env['warden'].message
    if session[:return_to].nil?
      redirect '/'
    else
      redirect session[:return_to]
    end
  end
  get '/auth/logout' do
    env['warden'].raw_session.inspect
    env['warden'].logout
    flash[:success] = 'Successfully logged out'
    redirect '/'
  end
  post '/auth/unauthenticated' do
    session[:return_to] = env['warden.options'][:attempted_path] if session[:return_to].nil?
    # Set the error and use a fallback if the message is not defined
    flash[:error] = env['warden.options'][:message] || "You must log in"
    redirect '/auth/login'
  end
end