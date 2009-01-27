class EntryController < ApplicationController
  before_filter :login_required

  NUM_DEFAULT = '15'

  verify :only => :list,
          :method => :get,
          :add_flash => {:error => 'verify failed'},
          :redirect_to => {:action => 'list'}

  def list
    @room = params[:room]
    @user = params[:user]
    @service = params[:service]
    @start = (params[:start] || '0').to_i
    @num = (params[:num] || NUM_DEFAULT).to_i
    @entry_fold = (!@user and !@service and params[:fold] != 'no')
    opt = {
      :start => @start,
      :num => @num,
      :service => @service
    }
    if @user
      @entries = ff_client.get_user_entries(@auth.name, @auth.remote_key, @user, opt)
    elsif @room
      room = @room
      room = nil if room == '*'
      @entries = ff_client.get_room_entries(@auth.name, @auth.remote_key, room, opt)
    else
      @entries = ff_client.get_home_entries(@auth.name, @auth.remote_key, opt)
    end
    @compact = true
    @post = true
    @post_comment = false
    @entries ||= []
  end

  def index
    redirect_to :action => 'list'
  end

  verify :only => :show,
          :method => :get,
          :params => [:id],
          :add_flash => {:error => 'verify failed'},
          :redirect_to => {:action => 'list'}

  def show
    @eid = params[:id]
    @entries = ff_client.get_entry(@auth.name, @auth.remote_key, @eid)
    @compact = false
    @post = false
    @post_comment = true
    @entries ||= []
    render :action => 'list'
  end

  def new
    @room = params[:room]
  end

  verify :only => :add,
          :method => :post,
          :params => [:body],
          :add_flash => {:error => 'verify failed'},
          :redirect_to => {:action => 'list'}

  def add
    body = params[:body]
    link = params[:link]
    room = params[:room]
    link = nil if link and link.empty?
    room = nil if room and room.empty?
    if body
      ff_client.post(@auth.name, @auth.remote_key, body, link, nil, nil, nil, room)
    end
    redirect_to :action => 'list'
  end

  verify :only => :delete,
          :method => :get,
          :params => [:id],
          :add_flash => {:error => 'verify failed'},
          :redirect_to => {:action => 'list'}

  def delete
    id = params[:id]
    comment = params[:comment]
    do_delete(id, comment, false)
    flash[:deleted_id] = id
    flash[:deleted_comment] = comment
    redirect_to :action => 'list'
  end

  verify :only => :undelete,
          :method => :get,
          :params => [:id],
          :add_flash => {:error => 'verify failed'},
          :redirect_to => {:action => 'list'}

  def undelete
    id = params[:id]
    comment = params[:comment]
    do_delete(id, comment, true)
    redirect_to :action => 'list'
  end

  def do_delete(id, comment = nil, undelete = false)
    if comment and !comment.empty?
      logger.info([id, comment, undelete].inspect)
      ff_client.delete_comment(@auth.name, @auth.remote_key, id, comment, undelete)
    else
      logger.info([id, comment, undelete].inspect)
      ff_client.delete(@auth.name, @auth.remote_key, id, undelete)
    end
  end

  verify :only => :add_comment,
          :method => :post,
          :params => [:id, :body],
          :add_flash => {:error => 'verify failed'},
          :redirect_to => {:action => 'list'}

  def add_comment
    eid = params[:id]
    body = params[:body]
    if eid and body
      ff_client.post_comment(@auth.name, @auth.remote_key, eid, body)
    end
    redirect_to :action => 'list'
  end
end