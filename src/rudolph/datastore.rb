require 'yaml'

class Rudolph
  class Datastore    
    def initialize
      @path = File.join(data_path, "data.yml")
    end
    
    def get_credentials
      YAML::load_file(@path).tap { |a| a[1] = cipher.decrypt_string a[1] }
    end
    
    def store_credentials username, password, first_time
      Rudolph::Crypt.generate_keys(data_path) if first_time
      puts "#{cipher.encrypt_string(password)}******#{password}"
      File.open(@path, 'w') { |f| YAML::dump([username, cipher.encrypt_string(password)], f) }
    end

    def data_path
      @datapath||=lambda do
        RUBY_PLATFORM =~ /win32/ ? File.expand_path(Dir.getwd) : File.expand_path(File.join("~", ".rudolph"))
      end.call.tap{|udd| Dir.mkdir(udd) unless File.exist?(udd)}
    end

    def cipher
      @cipher||=Rudolph::Crypt.new data_path
    end

  end
end