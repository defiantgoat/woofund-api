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
    payload = {
      :errors => [],
      :data => nil
    }

    if !params[:token] || params[:token]&.empty?
      payload[:errors].push('Request requires a token.')
      return [401, {'Content-Type': 'application/json'}, payload.to_json]
    end

    token_status = WooWooFund::TokenValidation.validate(params[:token])

    if token_status[:status_code] < 1
      payload[:errors].push(token_status)
      return [401, {'Content-Type': 'application/json'}, payload.to_json]
    end

    # For POC we will assume that the token is for the correct user and has the correct claims.
    user = token_status[:payload]['user']['email']
    database = File.read('./database.json')
    data_hash = JSON.parse(database)
    user_data = data_hash[user]

    payload[:data] = user_data
    puts(payload)

    [200, {'Content-Type': 'application/json'}, payload.to_json]
  end

  # Create a new pitch deck for user and return metadata
  post '/pitch/new' do
    payload = {
      :errors => [],
      :data => []
    }

    bearer_token = request.env['HTTP_AUTHORIZATION']&.split(' ')

    unless bearer_token
      payload[:errors].push('Request requires a token.')
      return [401, {'Content-Type': 'application/json'}, payload.to_json]
    end

    token_status = WooWooFund::TokenValidation.validate(bearer_token[1])

    if token_status[:status_code] < 1
      payload[:errors].push(token_status)
      return [401, {'Content-Type': 'application/json'}, payload.to_json]
    end

    campaign_name = request.params['name']
    snippet = request.params['snippet']
    about = request.params['about']
    goal_value = request.params['goal_value']
    pitch_deck = request.params['pitch_deck']

    user = token_status[:payload]['user']['email']
    database = File.read('./database.json')
    data_hash = JSON.parse(database)
    user_data = data_hash[user]

    campaign_id = user_data.count + 1

    new_record = {
      'id' => campaign_id,
      'name' => campaign_name,
      'snippet' => snippet,
      'about' => about,
      'goal_value' => goal_value,
      'current_value' => 0,
      'thumbnail': 'http://localhost:9292/api/static/placeholder.png',
    }

    pitch_deck_arr = []

    begin
      FileUtils.mkdir_p "./public/users/#{user}/#{campaign_id}"

      in_file = File.open(pitch_deck[:tempfile], 'rb')
      im = Magick::Image.read(in_file)
      im.each_with_index { |img, i, |
        puts "Geometry: #{img.columns}x#{img.rows}"
        puts "Resolution: #{img.x_resolution.to_i}x#{img.y_resolution.to_i} " +
               "pixels/#{img.units == Magick::PixelsPerInchResolution ?
                           "inch" : "centimeter"}"
        if img.properties.length > 0
          puts "   Properties:"
          img.properties { |name,value|
            puts %Q|      #{name} = "#{value}"|
          }
        end
        img.format=('JPG')
        img.resize!(2)
        img.write("./public/users/#{user}/#{campaign_id}/slide#{i}.jpg") {
          self.quality = 100
        }
        pitch_deck_arr.push({
                              'width' => img.columns * 2,
                              'height' => img.rows * 2,
                              'url' => "http://localhost:9292/api/users/#{user}/#{campaign_id}/slide#{i}.jpg"
                            })
      }

      new_record['pitch_deck'] = pitch_deck_arr
      payload[:data].push(new_record)
      user_data.push(new_record)
      data_hash[user] = user_data
      File.write('./database.json', JSON.dump(data_hash))
    rescue => e
      payload[:errors].push(e.to_s)
    end

    [200, {'Content-Type': 'application/json'}, payload.to_json]
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