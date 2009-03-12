class SettingController < ApplicationController
  before_filter :login_required
  after_filter :strip_heading_spaces
  after_filter :compress

  def initialize
    super
  end

  def index
    @font_size = (param(:font_size) || @setting.font_size).to_i
    @entries_in_page = (param(:entries_in_page) || @setting.entries_in_page).to_i
    @entries_in_thread = (param(:entries_in_thread) || @setting.entries_in_thread).to_i
    @text_folding_size = (param(:text_folding_size) || @setting.text_folding_size).to_i
    @list_view_media_rendering = param(:list_view_media_rendering) || @setting.list_view_media_rendering
    @link_open_new_window = param(:link_open_new_window) || @setting.link_open_new_window
    @link_type = param(:link_type) || @setting.link_type
  end

  def update
    updated = false
    original_value = {}
    [:font_size, :entries_in_page, :entries_in_thread, :text_folding_size, :list_view_media_rendering, :link_open_new_window, :link_type].each do |key|
      original_value[key] = @setting.send(key)
    end
    # int settings
    [:font_size, :entries_in_page, :entries_in_thread, :text_folding_size].each do |key|
      if param(key)
        instance_variable_set('@' + key.to_s, param(key))
        @setting.send(key.to_s + '=', param(key).to_i)
        updated = true
      end
    end
    @setting.list_view_media_rendering = (param(:list_view_media_rendering) == 'checked')
    @setting.link_open_new_window = (param(:link_open_new_window) == 'checked')
    @setting.link_type = nil
    if param(:link_type_gwt) == 'checked'
      @setting.link_type = 'gwt'
    end
    if errors = @setting.validate
      original_value.each do |key, value|
        @setting.send(key.to_s + '=', value)
      end
      flash[:error] = 'Settings error: ' + errors.join(", ")
      render :action => 'index'
    else
      flash[:message] = 'Settings updated.'
      redirect_to :controller => 'entry', :action => 'list'
    end
  end
end
