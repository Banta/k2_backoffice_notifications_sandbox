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
  "Go to /bca.json for the JSON response for HTTP POST notifications. More to come..."
end

# Request from Kopo Kopo
# GET /bca?format=json&merchant_identifier=fGVDOYMhjyojmEJ74lwBow==\n&aggregate_transactions_volume=371404&total_transactions_count&20&macc_description=Other
#
# Response from AFB
# {"status": "01", "description": "Accepted", "merchant_identifier": "fGVDOYMhjyojmEJ74lwBow==\n",
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

  symmetric_key = 'kopokopoafbsecretkey' # Shared key between AFB and Kopo Kopo
  status 200
  content_type :json

  # Parameters received from Kopo Kopo
  s_params = {merchant_identifier: params[:merchant_identifier],
            aggregate_transactions_volume: params[:aggregate_transactions_volume],
            total_transactions_count: params[:total_transactions_count],
            macc_description: params[:macc_description]}

  signature =  sign_params(s_params, symmetric_key)

  if signature == params[:signature]
    { :status => '01',
      :description => 'Accepted',
      :merchant_identifier => params['merchant_identifier'],
      :loan_amount => {:minimum => 1200, :maximum => 88000},
      :percentage_retrieval_rate => {:minimum => 20, :maximum => 60},
      :table => jsn}.to_json
  else
    { :status => '02',
      :description => 'Rejected'}.to_json
  end

end

def sign_params(params, symmetric_key)
  # Normalize the parameters and generate a base string for the signature
  base_string = ((params.to_a.map do |(key, value)|
    # Convert to string to allow sorting.
    [key.to_s, value.to_s]
  end).sort.inject([]) do |accu, (key, value)|
    accu << encode(key) + '=' + encode(value)
    accu
  end).join('&')

  signature = Base64.encode64(Digest::HMAC.digest(
                                  base_string, symmetric_key, Digest::SHA1
                              )).strip

  return signature
end

def encode(value)
  value = value.to_s if value.kind_of?(Symbol)
  return Addressable::URI.encode_component(
      value,
      Addressable::URI::CharacterClasses::UNRESERVED
  )
end

def parameterize(params)
  ((params.to_a.map do |(key, value)|
    # Convert to string to allow sorting.
    [key.to_s, value.to_s]
  end).inject([]) do |accu, (key, value)|
    accu << KopoKopo::Hooks.encode(key) + '=' + KopoKopo::Hooks.encode(value)
    accu
  end).join('&')
end

def jsn
  json_data = {}
    c = 3
    c1 = 10
    for i in 20..60 do
      json_data["#{i}"] =  {}

      for j in c..c1 do
        json_data["#{i}"]["#{ (j * 1000) + 1000}"] = (j * 1000) + 1000 + (j * 500) 
      end

      c += 1;
      c1 += 5;
    end
    json_data
end