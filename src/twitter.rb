require 'rudolph'

Shoes.app :title => Rudolph::SYS_USR, :width => Rudolph::APP_WIDTH, 
:height => Rudolph::APP_HEIGHT, :resizable => Rudolph::APP_RESIZABLE do

  def init
    @dstore = Rudolph::Datastore.new
    @username, @password = @dstore.get_credentials
    rescue Exception => e
      ask_credentials true
  end
  
  def ask_credentials first_time=false
    @username     = ask("Username")
    @password     = ask("Password")
    if @username.nil? || @password.nil? || @username.empty? || @password.empty?
      render_update Rudolph::SYS_USR, Rudolph.message(:invalid_login_pass)
      ask_credentials first_time
    else
      @dstore.store_credentials @username, @password, first_time
    end
  end

  def refresh_updates
    @anchor.nil? ? args = "" : args = "?since_id=#{@anchor}"

    req = Rudolph::HTTP.get @username, @password, "/statuses/friends_timeline.xml#{args}"

    if_valid(req) do
      l = []
      doc = REXML::Document.new(req.body)
      doc.elements.tap do 
        |elems| @anchor = elems[1].text('/statuses/status/id') 
      end.each('/statuses/status') do |e|
        l << [e.text("user/screen_name"), e.text("text")]
      end
      l.reverse.each { |user,text| render_update user, text }
    end
  end

  def send_update user, password, message
    if message.size < 3 || message.size > 140 
      return render_update Rudolph::SYS_USR, Rudolph.message(:invalid_update_size)
    end
    req = Rudolph::HTTP.post @username, @password, message, '/statuses/update.xml'
    
    if_valid(req) do
      doc = REXML::Document.new(req.body)
      @anchor = doc.text('/status/id')
      render_update user, message
    end
  end

  def render_update user, message
    @gui_status.prepend do
      stack  :margin => Rudolph::UPDT_MARGIN  do
        if user == Rudolph::SYS_USR
          background "#eee", :curve => Rudolph::UPDT_CURVE
        else
          background "#fff",    :curve => Rudolph::UPDT_CURVE
        end
        para strong(user, :stroke => "#00f"), ' ', message, :margin => Rudolph::UPDT_PMARGIN
      end
    end
  end

  def if_valid(request)    
    case request
    when Net::HTTPSuccess, Net::HTTPRedirection
      yield
    when Net::HTTPClientError
      render_update Rudolph::SYS_USR, Rudolph.message(:authentication_failed)
      ask_credentials
    when Net::HTTPServerError
      render_update SYS_USR, Rudolph.message(:server_not_responding)
    end
  end

  background rgb(154, 228, 232, 1.0)
  stack :margin => Rudolph::MAIN_MARGIN do
    caption Rudolph::SYS_USR, :stroke => "#fff", :align => 'right'
    stack do
      @box = edit_box "", :width => Rudolph::STACKS_WIDTH, :height => Rudolph::UPDTBOX_HEIGHT, :margin => Rudolph::STACKS_MARGIN
      button("update") { send_update(@username, @password, @box.text); @box.text = ""  }
    end
    stack :width => Rudolph::STACKS_WIDTH, :height => Rudolph::MSGSTACK_HEIGHT, :scroll => true, :margin => Rudolph::STACKS_MARGIN do
      @gui_status = stack :margin_right => gutter
    end
    every(60) { refresh_updates }
  end
  
  init
  refresh_updates
end
