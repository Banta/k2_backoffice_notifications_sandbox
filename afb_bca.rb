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

get '/' do
  "/"
end

get '/encryptdecrypt' do
  salt = params[:salt]
  secret_key = params[:secret_key]
  output = "Enter correct salt, secret_key and either encrypt or decrypt" << "<br /><br /><a href='/xhfgduv267riqwd'>Go back</a></b>"

  if params[:method] == 'encrypt'
    begin
      encrypted_merchant_identifier = Encryptor.encrypt(params[:id].to_s, key: secret_key, salt: salt)
      output = "Encrypted id: <b>#{Base64.strict_encode64(encrypted_merchant_identifier)}</b>" << "<br /><br /><b><a href='/xhfgduv267riqwd'>Go back</a></b>"
    rescue => e
      puts "Error: #{e}"
    end
  elsif params[:method] == 'decrypt'
    begin
      decoded_merchant_identifier = Base64.decode64(params[:id].to_s)
      output = "Plain id: <b>#{Encryptor.decrypt(decoded_merchant_identifier, key: secret_key, salt: salt)}</b>" << "<br /><br /><b><a href='/xhfgduv267riqwd'>Go back</a></b>"
    rescue => e
      puts "Error: #{e}"
    end
  else
    output = "Pass salt, secret_key and either encrypt or decrypt" << "<br /><br /><b><a href='/xhfgduv267riqwd'>Go back</a></b>"
  end

  output
end

get '/xhfgduv267riqwhfhd' do
   erb :xhfgduv267riqwd
end

#use Rack::Auth::Basic, "Restricted Area" do |username, password|
#  username == 'username12' and password == 'password12'
#end

get '/bca.json' do

  symmetric_key = 'i0IVNFPMBdfd3lT2AODi' # Shared key between AFB and Kopo Kopo
  content_type :json

  # Parameters received from Kopo Kopo
  params_from_k2 = {aggregate_transactions_volume: params[:aggregate_transactions_volume].to_i,
              total_transactions_count: params[:total_transactions_count].to_i,
              macc_description: params[:macc_description],
              merchant_identifier: params[:merchant_identifier]}


  p "\nParameters ==> #{params_from_k2.to_s} --\n"
  p "\nsignature ==>" << params[:signature] << "\n"

  signature = getSignature(params_from_k2, symmetric_key)

  p "Sig " << signature << " == " << params[:signature]

  if true
    table = genetate_table # The method that generates the table
    signature = get_hmac(params['merchant_identifier'], table.to_json, symmetric_key)

    status 200
    {
        :merchant_identifier => params[:merchant_identifier],
        :table => table,
        :signature => signature
    }.to_json
  else
    status 403
    {:status => '02',
     :description => 'Rejected'}.to_json
  end

end

post '/receive_bca_notification' do

  signature = params["signature"]
  params.delete("signature")

  if signature == getSignature(params, "YSCgk1haV0kS1P9+FXIR")
    status 200
    {message: "Received successfully"}.to_json
  else
    status 403
    {message: "Rejected"}.to_json
  end
end


def getSignature(params, symmetric_key)
  puts params.to_json
  signature = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), symmetric_key, params.to_json).to_s
  Base64.encode64(signature)
end

def genetate_table
  json_data = {}
  c = 3
  c1 = 10
  for i in 20..60 do
    json_data["#{i}"] = {}

    for j in c..c1 do
      json_data["#{i}"]["#{ (j * 1000) + 1000}"] = (j * 1000) + 1000 + (j * 500)
    end

    c += 1;
    c1 += 5;
  end
  json_data
end

def get_hmac(merchant_identifier, table, symmetric_key)
  digest = OpenSSL::Digest.new('sha1')
  hmac = OpenSSL::HMAC.digest(digest, symmetric_key, (merchant_identifier || '') + (table || ''))
  Base64.encode64(hmac.to_s)
end