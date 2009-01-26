module EntryHelper
  FF_ICON_URL_BASE = 'http://friendfeed.com/static/images/'
  LIKE_ICON_URL = FF_ICON_URL_BASE + 'smile.png'
  COMMENT_ICON_URL = FF_ICON_URL_BASE + 'comment-lighter.png'
  DELETE_ICON_URL = FF_ICON_URL_BASE + 'delete.png'

  def icon(entry)
    service_icon(v(entry, 'service'))
  end

  def service(entry)
    room = v(entry, 'room')
    if room
      room(room)
    else
      name = v(entry, 'service', 'name')
      service_id = v(entry, 'service', 'id')
      user = v(entry, 'user', 'nickname')
      if name and service_id
        if user
          link_to(h(name), :controller => 'entry', :action => 'list', :user => u(user), :service => u(service_id))
        else
          # pseudo friend!
          h(name)
        end
      end
    end
  end

  def content(entry)
    common = common_content(entry)
    service_id = v(entry, 'service', 'id')
    case service_id
    when 'brightkite'
      brightkite_content(common, entry)
    when 'twitter'
      twitter_content(common, entry)
    else
      common
    end
  end

  def common_content(entry)
    title = v(entry, 'title')
    link = v(entry, 'link')
    if link and with_link?(v(entry, 'service'))
      content = link_to(h(q(title)), link)
    else
      content = h(q(title))
    end
    medias = v(entry, 'media')
    if medias and !medias.empty?
      content += "<br/>\n" + content_with_media(title, medias)
    end
    content
  end

  def with_link?(service)
    service_id = v(service, 'id')
    entry_type = v(service, 'entryType')
    entry_type != 'message' and !['twitter'].include?(service_id)
  end

  def content_with_media(title, medias)
    medias.collect { |media|
      media_title = v(media, 'title')
      media_link = v(media, 'link')
      tbs = v(media, 'thumbnails')
      if tbs and !tbs.empty?
        safe_content = tbs.collect { |tb|
          tb_url = v(tb, 'url')
          tb_width = v(tb, 'width')
          tb_height = v(tb, 'height')
          if tb_url
            image_tag(tb_url,
              :alt => h(media_title), :size => image_size(tb_width, tb_height))
          end
        }.join(' ')
      else
        safe_content = h(media_title)
      end
      link_to(safe_content, media_link)
    }.join(' ')
  end

  def brightkite_content(common, entry)
    lat = v(entry, 'geo', 'lat')
    long = v(entry, 'geo', 'long')
    if lat and long
      zoom = 13
      width = 160
      height = 80
      tb = "http://maps.google.com/staticmap?zoom=#{h(zoom)}&size=#{image_size(width, height)}&maptype=mobile&markers=#{lat},#{long}"
      title = v(entry, 'title')
      link = "http://maps.google.com/maps?q=#{lat},#{long}+%28#{u(title)}%29"
      content = link_to(image_tag(tb, :alt => h(title), :size => image_size(width, height)), link)
      medias = v(entry, 'media')
      if medias and !medias.empty?
        common + ' ' + content
      else
        common + "<br/>\n" + content
      end
    else
      common
    end
  end

  # TODO: uglish
  def twitter_content(common, entry)
    common = common.sub(/\A&quot;(.*)&quot;\z/) { $1 }
    common = common.gsub(/((?:http|https):\/\/\S+)/) { link_to(h($1), $1) }
    common = common.gsub(/@([a-zA-Z0-9_]+)/) {
      link_to('@' + $1, "http://twitter.com/#{$1}")
    }
    '&quot;' + common + '&quot;'
  end

  def via(entry)
    super(v(entry, 'via'))
  end

  def likes(entry)
    likes = v(entry, 'likes')
    if likes and !likes.empty?
      like_icon + v(entry, 'likes').collect { |like| user(like) }.join(' ')
    end
  end

  def published(entry, compact)
    published = v(entry, 'published')
    date(published, compact)
  end

  def user(entry)
    super(v(entry, 'user'))
  end

  def like_icon
    image_tag(LIKE_ICON_URL, :alt => 'like')
  end

  def comment_icon
    image_tag(COMMENT_ICON_URL, :alt => 'comment')
  end

  def delete_icon
    image_tag(DELETE_ICON_URL, :alt => 'delete')
  end

  def comment(comment)
    h(v(comment, 'body'))
  end

  def post_comment_form
    str = ''
    room = (@room != '*') ? @room : nil
    if room
      str = hidden_field_tag('room', room) + h(room) + ': '
    end
    str += text_field_tag('body') + submit_tag('post')
    str += ' ' + link_to(h('[extended]'), :action => 'new', :room => u(room))
    str
  end

  def logout_link
    link_to(h('[logout]'), :controller => 'login', :action => 'clear')
  end

  def page_links
    return unless defined?(@start)
    links = []
    label = '[<<]'
    if @start - @num >= 0
      links << link_to(h(label), list_opt(:action => 'list', :start => 0, :num => @num))
    else
      links << h(label)
    end
    label = '[<]'
    if @start - @num >= 0
      links << link_to(h(label), list_opt(:action => 'list', :start => @start - @num, :num => @num))
    else
      links << h(label)
    end
    label = '[home]'
    if @room or @user or @service
      links << link_to(h(label), :action => 'list')
    else
      links << h(label)
    end
    label = '[rooms]'
    if @room == '*'
      links << h(label)
    else
      links << link_to(h(label), :action => 'list', :room => '*')
    end
    label = '[>]'
    links << link_to(h(label), list_opt(:action => 'list', :start => @start + @num, :num => @num))
    links.join(' ')
  end

  def post_comment_link(entry)
    eid = v(entry, 'id')
    link_to(comment_icon, :action => 'show', :id => u(eid))
  end

  def delete_link(entry)
    eid = v(entry, 'id')
    name = v(entry, 'user', 'nickname')
    if name == @auth.name
      link_to(delete_icon, {:action => 'delete', :id => u(eid)}, :confirm => 'Are you sure?')
    end
  end

  def undelete_link(id, comment)
    link_to(h('Deleted.  UNDO?'), :action => 'undelete', :id => u(id), :comment => u(comment))
  end

  def delete_comment_link(entry, comment)
    eid = v(entry, 'id')
    cid = v(comment, 'id')
    name = v(comment, 'user', 'nickname')
    if name == @auth.name
      link_to(delete_icon, {:action => 'delete', :id => u(eid), :comment => u(cid)}, :confirm => 'Are you sure?')
    end
  end

  def list_opt(hash = {})
    {
      :room => @room,
      :user => @user,
      :service => @service
    }.merge(hash)
  end

  class Fold
    attr_accessor :fold_entries

    def initialize(fold_entries)
      @fold_entries = fold_entries
    end
  end

  def fold(entries)
    result = []
    seq = 0
    prev = nil
    entries.each do |entry|
      pair = [v(entry, 'user', 'nickname'), v(entry, 'service', 'id')]
      if pair == prev
        seq += 1
      else
        if seq >= 2
          result << Fold.new(seq - 1)
        end
        seq = 0
      end
      prev = pair
      if seq < 2
        result << entry
      end
    end
    result
  end
end
