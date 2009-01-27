require 'httpclient'


class LoginController < ApplicationController
  def index
    if ensure_login
      redirect_to :controller => 'entry'
    end
  end

  def clear
    logout
    redirect_to :action => 'index'
  end

  def authenticate
    name, remote_key = params[:name], params[:remote_key]
    if ff_client.validate(name, remote_key)
      user = User.new
      user.name = name
      user.remote_key = remote_key
      unless user.save
        flash[:error] = 'illegal auth credentials given'
        redirect_to :action => 'index'
      end
      set_user(user)
      redirect_to :controller => 'entry'
    else
      redirect_to :action => 'index'
    end
  end
end