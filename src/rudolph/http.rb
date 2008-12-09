class Rudolph
  class HTTP
    OPEN_TIMEOUT = 3
    READ_TIMEOUT = 3

    def self.get path, username, password
      Rudolph::HTTP.connect(Rudolph::API_URI, username, password) do
        Net::HTTP::Get.new path
      end
    end
    
    def self.post path, username, password, message
      Rudolph::HTTP.connect(Rudolph::API_URI, username, password, {:status => message, :source => Rudolph::TWITTER_SRC}) do
        Net::HTTP::Post.new path
      end
    end
    
    def self.get_theme username
      req = Net::HTTP.start(Rudolph::API_URI) do |http| 
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT
        http.request Net::HTTP::Get.new("/users/show/#{username}.xml")
      end
      doc  = REXML::Document.new(req.body)
      text = doc.text('/user/profile_text_color')
      bg   = doc.text('/user/profile_background_color')
      link = doc.text('/user/profile_link_color')
      img  = doc.text('/user/profile_background_image_url')
      sb_b = doc.text('/user/profile_sidebar_border_color')
      sb   = doc.text('/user/profile_sidebar_fill_color')

      if text.nil? || bg.nil? or link.nil? or sb.nil?
        Rudolph::DEF_THEME
      else
        { 
          :background     => "##{bg}", 
          :text           => "##{text}",
          :link           => "##{link}",
          :sidebar        => "##{sb}",
          :sidebar_border => "##{sb_b}",
          :image          => img, 
          :image_tile     => (doc.text('/user/profile_background_tile') == 'true')
        }
      end
    end

    def self.connect(url, username, password, *args)
      req = yield
      req.basic_auth username, password
      req.set_form_data(args[0]) if req.class.to_s.include?('Post')
      Net::HTTP.start(url) do |http|
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT
        http.request(req) 
      end
    end
  end
end