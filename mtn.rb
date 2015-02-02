require 'sinatra'
require 'json'
require 'base64'
require 'addressable/uri'
require './lib/encryptor'
include Encryptor
begin
  require 'digest/hmac'
rescue LoadError
  require 'compat/digest/hmac'
end
require 'digest/sha1'


post '/ThirdPartyServiceUMMImpl/UMMServiceService/RequestPayment/v17' do
  File.open('response.xml').read
end

post '/api/private/v1/financial_transactions' do
   if params[:authentication_token] == authentication_token
     p params.inspect
     # Sinatra.logger.info(params.inspect)
   else
     p 'Not authorized'
     # Sinatra.logger.info('Not authorized')
   end
end

def authentication_token
  # MurmurHash3::V32.str_hash('k0p0.k0p0')
end
