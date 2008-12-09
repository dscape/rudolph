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
    @password     = ask("Password", :secret => true)
    if @username.nil? || @password.nil? || @username.empty? || @password.empty?
      alert Rudolph::SYS_USR, Rudolph.message(:invalid_login_pass)
      ask_credentials first_time
    else
      @dstore.store_credentials @username, @password, first_time
    end
  end

  def update_theme
    @theme = Rudolph::HTTP.get_theme @username
  end

  def refresh_updates
    @anchor.nil? ? args = "" : args = "?since_id=#{@anchor}"
    req = Rudolph::HTTP.get "/statuses/friends_timeline.xml#{args}", @username, @password
    if_valid(req) do
      l = []
      doc = REXML::Document.new(req.body)
      doc.elements.tap do 
        |elems| @anchor = elems[1].text('/statuses/status/id') if elems[1].text('/statuses/status/id').is_a?(String)
      end.each('/statuses/status') do |e|
        l << [e.text("user/screen_name"), e.text("text")]
      end
      l.reverse.each { |user,text| render_update user, text }
    end
  end

  def send_update user, password, message
    if message.size < 3 || message.size > 140 
      render_update Rudolph::SYS_USR, Rudolph.message(:invalid_update_size)
      return message
    else
      req = Rudolph::HTTP.post '/statuses/update.xml', @username, @password, message

      if_valid(req) do
        doc = REXML::Document.new(req.body)
        @anchor = doc.text('/status/id')
        render_update user, message
      end
      return ""
    end
  end

  def render_update user, message
    @gui_status.prepend do
      stack  :margin => Rudolph::UPDT_MARGIN  do
        if user == Rudolph::SYS_USR
          background @theme[:sidebar], :curve => Rudolph::UPDT_CURVE
        else
          background "#fff", :curve => Rudolph::UPDT_CURVE
        end
        eval "para strong(user, :stroke => @theme[:link]), \" \", #{process_links message}, :margin => Rudolph::UPDT_PMARGIN"
      end
    end
  end
  
  def process_links message
    message.gsub("\"","'").split.map do |token|
      if token =~ /((http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
        %Q(link("#{token }", :click => "#{token}", :stroke => @theme[:link]), ' ')
      elsif token =~ /@[a-z0-9_]+/i
        %Q(\"@\", link("#{token.gsub('@','')}", :click => "http://www.twitter.com/#{token.gsub('@','')}", :stroke => @theme[:link]), ' ')
      elsif token =~ /#[a-z0-9_]+/i
        %Q(\"\#\", link("#{token.gsub('#','')}", :click => "http://www.hashtags.org/tag/#{token.gsub('#','')}", :stroke => @theme[:link]), ' ')
      else
        "\"#{token} \""
      end
    end.join(', ')
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
  
  def set_chr_size char_count
    remaining = Rudolph::TWITTER_LIMIT - char_count
    remaining < 21 ? strk = @theme[:link] : strk = @theme[:text]
    @chr_size.replace remaining, :stroke => strk, :align => 'right'
  end

  init
  update_theme

  background @theme[:background]
  #image @theme[:image] unless @theme[:image].nil? 
  stack :margin => Rudolph::MAIN_MARGIN do
    @chr_size = caption Rudolph::TWITTER_LIMIT.to_s, :stroke => @theme[:text], :align => 'right'
    stack do
      @box = edit_box("", :width => Rudolph::STACKS_WIDTH, :height => Rudolph::UPDTBOX_HEIGHT, :margin => Rudolph::STACKS_MARGIN) do
        set_chr_size @box.text.length
      end
      button("update") { @box.text = send_update(@username, @password, @box.text); set_chr_size(@box.text.length) }
    end
    stack :width => Rudolph::STACKS_WIDTH, :height => Rudolph::MSGSTACK_HEIGHT, :scroll => true, :margin => Rudolph::STACKS_MARGIN do
      @gui_status = stack :margin_right => gutter
    end
    every(60) { refresh_updates }
  end
  
  refresh_updates
end
