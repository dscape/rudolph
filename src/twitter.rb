require 'uri'
require 'net/http'
require 'rexml/document'
require 'sqlite3'

DEBUG       = true
SYS_USR     = 'RUDOLPH'
API_URI     = 'twitter.com'
VERSION     = '0.2b'

Shoes.app :title => "Rudolph", :width => 450, :height => 600, :resizable => false do

  def init
    @anchor = nil
    database_path = File.join(data_path, "data.db")
    @db = SQLite3::Database.new database_path
    @db.execute("select user, password from rudolph").first
  rescue Exception
    config_env @db, true
  end

  def config_env db, first_time=false
    @user = ask("username")
    @password = ask("password")
    db.execute "create table rudolph(user varchar(64), password varchar(64))" if first_time
    db.execute "insert into rudolph(user, password) values (?, ?)", @user, @password
    [@user, @password]
  end

  def twitter_connect(url, *args)
    req = yield
    req.basic_auth(@user, @password)
    req.set_form_data(args[0]) if req.class.to_s.include?('Post')
    Net::HTTP.start(url) { |http| http.request(req) }
  rescue Exception => e
    render_update SYS_USR, e
  end

  def refresh_updates
    @anchor.nil? ? args = "" : args = "?since_id=#{@anchor}"

    req = twitter_connect(API_URI) { Net::HTTP::Get.new "/statuses/friends_timeline.xml#{args}" }

    if_valid(req) do
      l = []
      doc = REXML::Document.new(req.body)
      elems = doc.elements
      @anchor = elems[1].text('/statuses/status/id')
      elems.each('/statuses/status') do |e|
        l << [e.text("user/screen_name"), e.text("text")]
      end
      l.reverse.each { |user,text| render_update user, text }
    end
  end

  def send_update user, password, message
    return render_update(SYS_USR, "Your message must have between 3 and 140 chars") if message.size < 3 || message.size > 140 
    req = twitter_connect(API_URI, {:status => message, :source => 'rudolph'}) { Net::HTTP::Post.new('/statuses/update.xml') } 
    if_valid(req) { refresh_updates }
  end

  def render_update user, message
    @gui_status.prepend do
      stack  :margin => 10  do
        user == SYS_USR ? background("#ddd", :curve => 12) : background("#fff", :curve => 12)
        para strong(user, :stroke => blue), ' ', message, :margin => 10
      end
    end
  end

  def if_valid(request)    
    case request
    when Net::HTTPSuccess, Net::HTTPRedirection
      yield
    when Net::HTTPClientError
      render_update SYS_USR, "authentication failed (#{request.code})"
      config_env @db
    when Net::HTTPServerError
      render_update SYS_USR, "server is not responding (#{request.code})"
    end
  end

  def data_path
    RUBY_PLATFORM =~ /win32/ ? user_data_directory = File.expand_path(Dir.getwd) : user_data_directory = File.expand_path(File.join("~", ".rudolph"))
    Dir.mkdir(user_data_directory) unless File.exist?(user_data_directory)    
    return File.join(user_data_directory)
  end
  
  def debug_puts group, message
    puts "#{Time.now} #{SYS_USR}[#{VERSION}] *** (#{group}) #{message}" if DEBUG
  end

  background rgb(154, 228, 232, 1.0)
  stack :margin => 10 do
    caption 'Rudolph', :stroke => white, :align => 'right'
    stack do
      @user, @password = init
      @box = edit_box "", :width => 1.0, :height => 100, :margin => 5
      button("update") { send_update(@user, @password, @box.text); @box.text = ""  }
    end
    stack :width => 1.0, :height => 380, :scroll => true, :margin => 5 do
      @gui_status = stack :margin_right => gutter
    end
    every(60) { |i| refresh_updates }
    refresh_updates
  end
end