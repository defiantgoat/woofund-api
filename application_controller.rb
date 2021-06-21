require 'sinatra/base'
require 'rack/cors'
require_relative 'lib/woowoo_token_validation'
require 'rmagick'

class ApplicationController < Sinatra::Base

  # Default CORS headers plus Access-Control for pre-flight requests.
  headers = [
    'Cache-Control',
    'Content-Language',
    'Content-Type',
    'Expires',
    'Last-Modified',
    'Pragma',
    'Options',
    'Access-Control-Allow-Origin',
    'Access-Control-Allow-Headers',
    'Access-Control-Allow-Methods',
    'Authorization'
  ].freeze

  use Rack::Cors do
    allow do
      origins 'localhost:8080'
      resource '*',
               :headers => headers,
               :methods => [:get, :post, :patch, :options]
    end
  end

  def initialize(app = nil)
    super
  end

  get '/' do
    output = "<h2>WooWooFund API: Version 0.1.0</h2>"
    [200, {}, output]
  end

  # Get pitch deck metadata
  get '/pitch/:pitchid' do
    if !params[:token] || params[:token]&.empty?
      payload = {
        'errors' => [
          'Request requires a token.'
        ]
      }.to_json
      return [401, {'Content-Type': 'application/json'}, payload]
    end

    token_status = WooWooFund::TokenValidation.validate(params[:token])

    if token_status[:status_code] < 1
      return [401, {'Content-Type': 'application/json'}, token_status.to_json]
    end

    # For POC we will assume that the token is for the correct user and has the correct claims.
    user = token_status[:payload]['user']['id'].to_s
    database = File.read('./database.json')
    data_hash = JSON.parse(database)
    user_data = data_hash[user]

    payload = {
      'data' => user_data
    }.to_json

    [200, {'Content-Type': 'application/json'}, payload]
  end

  # Create a new pitch deck for user and return metadata
  post '/pitch/new' do
    puts request.params['pitch_deck']
    in_file = File.open(request.params['pitch_deck'][:tempfile], 'rb')
    im = Magick::Image.read(in_file)
    im.each do |img, i|
      img.write("./public/slide#{i}.jpg")
      # puts img.format
      # imgF = File.open("./public/users/slide#{i}.jpg", 'w+')
      # # imgFile = File.new("slide#{i}.jpg", 'w+')
      # img.write(imgF)
    end
    puts im
    # requires Authorization header with Bearer token
    # pdf, ppt, psd, ai
    #
    # For POC we will assume that the token is for the correct user and has the correct claims.
    #
    #     database = File.read('./database.json')
    #
    #     data_hash = JSON.parse(database)
    #
    #     user_data = data_hash['1']
    #     File.write('./sample-data.json', JSON.dump(data_hash))
    #
    [200, {'Content-Type': 'application/json'}, {'jayson' => 'yes'}.to_json]
  end

  # Update an existing pitch deck and return metadata
  patch '/pitch/:pitchid' do
    puts params[:pitchid]
    # For POC we will assume that the token is for the correct user and has the correct claims.

  end

  get '/health' do
    [200, {}, 'WooWooFund API is accepting requests and returning responses.']
  end

end