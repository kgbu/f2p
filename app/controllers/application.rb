# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'ff'


class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'b2dff3fcf9a2f9a3980713aebb79677f'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password

  def self.ff_client
    @@ff ||= FriendFeed::APIClient.new
  end

  def self.ff_client=(ff_client)
    @@ff = ff_client
  end

  def ff_client
    self.class.ff_client
  end

private

  def login_required
    unless ensure_login
      redirect_to :controller => 'login', :action => 'index'
    end
  end

  def ensure_login
    @user_id ||= session[:user_id]
    if @user_id
      @auth = User.find(@user_id)
    end
  end

  def set_user(user)
    @user_id = session[:user_id] = user.id
    @auth = user
  end

  def logout
    @user_id = session[:user_id] = nil
    @auth = nil
  end
end