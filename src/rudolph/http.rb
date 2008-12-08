class Rudolph
  class HTTP
    def self.get username, password, path
      Rudolph::HTTP.connect(Rudolph::API_URI, username, password) do
        Net::HTTP::Get.new path
      end
    end
    
    def self.post username, password, message, path
      Rudolph::HTTP.connect(Rudolph::API_URI, username, password, {:status => message, :source => Rudolph::TWITTER_SRC}) do
        Net::HTTP::Post.new path
      end
    end

    def self.connect(url, username, password, *args)
      req = yield
      req.basic_auth username, password
      req.set_form_data(args[0]) if req.class.to_s.include?('Post')
      Net::HTTP.start(url) { |http| http.request(req) }
    end
  end
end