require 'openssl'

# A simple wrapper for the standard OpenSSL library
module Encryptor
  extend self

  # Defaults to { :algorithm => 'aes-256-cbc' }
  #
  # Run 'openssl list-cipher-commands' in your terminal to view a list all cipher algorithms that are supported on your platform
  def default_options
    @default_options ||= { :algorithm => 'aes-256-cbc' }
  end

  # Example
  #   encrypted_value = Encryptor.encrypt('some string to encrypt', :key => 'some secret key')
  def encrypt(*args, &block)
    crypt :encrypt, *args, &block
  end

  # Example
  #   decrypted_value = Encryptor.decrypt('some encrypted string', :key => 'some secret key')
  def decrypt(*args, &block)
    crypt :decrypt, *args, &block
  end

  protected

    def crypt(cipher_method, *args) #:nodoc:
      options = default_options.merge(:value => args.first).merge(args.last.is_a?(Hash) ? args.last : {})
      raise ArgumentError.new('must specify a :key') if options[:key].to_s.empty?
      cipher = OpenSSL::Cipher::Cipher.new(options[:algorithm])
      cipher.send(cipher_method)
      if options[:iv]
        cipher.iv = options[:iv]
        if options[:salt].nil?
          # Use a non-salted cipher.
          cipher.key = options[:key]
        else
          # Use an explicit salt
          cipher.key = OpenSSL::PKCS5.pbkdf2_hmac_sha1(options[:key], options[:salt], 2000, cipher.key_len)
        end
      else
        cipher.pkcs5_keyivgen(options[:key])
      end
      yield cipher, options if block_given?
      result = cipher.update(options[:value])
      result << cipher.final
    end
end
