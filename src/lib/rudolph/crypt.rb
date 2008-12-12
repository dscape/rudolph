require 'openssl'
require 'Base64'

class Rudolph
  class Crypt
    def initialize data_path
      @data_path = data_path
      @private   = get_key 'id_rsa'
      @public    = get_key 'id_rsa.pub'
    end

    def encrypt_string message
      Base64::encode64(@public.public_encrypt(message)).rstrip
    end

    def decrypt_string message
      @private.private_decrypt Base64::decode64(message)
    end

    def self.generate_keys data_path
      rsa_path = File.join(data_path, 'rsa')
      privkey  = File.join(rsa_path, 'id_rsa')
      pubkey   = File.join(rsa_path, 'id_rsa.pub')
      unless File.exists?(privkey) || File.exists?(pubkey)
        keypair  = OpenSSL::PKey::RSA.generate(1024)
        Dir.mkdir(rsa_path) unless File.exist?(rsa_path)
        File.open(privkey, 'w') { |f| f.write keypair.to_pem } unless File.exists? privkey
        File.open(pubkey, 'w') { |f| f.write keypair.public_key.to_pem } unless File.exists? pubkey
      end
    end

    private
    def get_key filename
      OpenSSL::PKey::RSA.new File.read(File.join(@data_path, 'rsa', filename))
    end
  end
end