require 'sqlite3'

class Rudolph
  class Datastore    
    def initialize
      @db = SQLite3::Database.new File.join(data_path, "data.db")
    end
    
    def get_credentials
      @db.execute("select user, password from #{Rudolph::SQL_TABLE}").first.map { |u,p| [u,cipher.decrypt_string(p)]}
    end
    
    def insert username, password, first_time
      @db.execute "create table #{Rudolph::SQL_TABLE}(user varchar(256), password varchar(256))" if first_time
      @db.execute "insert into rudolph(user, password) values (?, ?)", username, cipher.encrypt_string(password)
    end

    def data_path
      @datapath||=lambda do
        RUBY_PLATFORM =~ /win32/ ? File.expand_path(Dir.getwd) : File.expand_path(File.join("~", ".rudolph"))
      end.call.tap{|udd| Dir.mkdir(udd) unless File.exist?(udd)}
    end

    def cipher
      @cipher||=Rudolph::Crypt.new(Digest::SHA1.hexdigest(data_path))
    end

  end
end