require 'uri'
require 'net/http'
require 'rexml/document'
require 'sqlite3'

SYS_USR = '#APP'
API_URI = 'twitter.com'

Shoes.app :title => "Rudolph", :width => 450, :height => 600, :resizable => false do

  def init
    @anchor = Time.parse 'Jan 01 2000'
    @db = SQLite3::Database.new File.join(data_path, "data.db")
    @db.execute("select user, password from rudolph").first
    rescue Exception
      config_env @db
  end
  
  def config_env db, first_time=true, user=nil, password=nil
    user.nil? ? @user = user : @user = ask("username")
    password.nil? ? @password = password : @password = ask("password")
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
	  render_update SYS_USR, e, true
  end

  def refresh_updates
    req = twitter_connect(API_URI) { |h| Net::HTTP::Get.new('/statuses/friends_timeline.xml') }
    doc = REXML::Document.new(req.body)
	temporary_anchor = nil
	l = []
    doc.elements.each('/statuses/status') do |e|
	  created_at = Time.parse e.text("created_at")
      break if created_at == @anchor
	  temporary_anchor = created_at if temporary_anchor.nil?
	  l << [e.text("user/screen_name"), e.text("text")]
    end
	l.reverse.each { |user,text| render_update user, text }
	@anchor = temporary_anchor
  end

  def send_update user, password, message
    return render_update(SYS_USR, "Your message must have between 3 and 140 chars", true) if message.size < 3 || message.size > 140 
    case twitter_connect(API_URI, {:status => message}) { |h| Net::HTTP::Post.new('/statuses/update.xml') } 
    when Net::HTTPSuccess, Net::HTTPRedirection
	  refresh_updates
    else
      render_update SYS_USR, "authentication failed. please re-enter your credentials #{res}", true
	  config_env @db, false
    end
  end

  def render_update user, message, sys=false
    @gui_status.prepend do
      stack  :margin => 10  do
        sys ? background("#ccc", :curve => 12) : background("#fff", :curve => 12)
        para strong(user, :stroke => blue), ' ', message, :margin => 10
      end
    end
  end
  
  def data_path
    RUBY_PLATFORM =~ /win32/ ? user_data_directory = File.expand_path(Dir.getwd) : user_data_directory = File.expand_path(File.join("~", ".rudolph"))
    Dir.mkdir(user_data_directory) unless File.exist?(user_data_directory)    
    return File.join(user_data_directory)
  end

  background rgb(154, 228, 232, 1.0)
  image "bg.gif", :top => 0, :left => 0
  stack :margin => 10 do
    title 'Rudolph', :stroke => white, :align => 'right'
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

  # referir url do twitter e como fazer
  # lembrar de eliminar alerts se possivel
  # por tudo command line like things para mudar configs
  # save with security, create private key and encrypt
  # refer better twitter implementations, just a sample
  # simple simple simple
  # make installer
  # create logo
  # skins, easy. use client colors from twitter
  #separate into modules