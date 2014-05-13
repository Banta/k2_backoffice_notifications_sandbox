require 'sinatra'
require 'json'
require 'base64'
require 'addressable/uri'
begin
  require 'digest/hmac'
rescue LoadError
  require 'compat/digest/hmac'
end
require 'digest/sha1'

get '/' do
  "#{Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), "key", "Nairobi").to_s)}"
end

# Request from Kopo Kopo
# GET /bca?format=json&merchant_identifier=fGVDOYMhjyojmEJ74lwBow==\n&aggregate_transactions_volume=371404&total_transactions_count&20&macc_description=Other
#
# Response from AFB
# { "merchant_identifier": "fGVDOYMhjyojmEJ74lwBow==\n",
#  "table": {
#     "20": {
#         "4000": 5500,
#         "5000": 7000,
#         "6000": 8500,
#         "7000": 10000,
#         "8000": 11500,
#         "9000": 13000,
#         "10000": 14500,
#         "11000": 16000
#     },
#     .
#     .
#     .
#     "60": {
#         "5000": 7000,
#         .
#         .
#         .
#         "16000": 23500
#     }

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

  if signature == params[:signature]
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

def getSignature(params, symmetric_key)
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