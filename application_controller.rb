require 'sinatra/base'
require_relative 'lib/woowoo_token_validation'

class ApplicationController < Sinatra::Base

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

    payload = {
      'data' => [
        {
          'id' => 100,
          'name' => 'Fund Me A Go Go',
          'about' => 'Lorem ipsum dolor',
          'goal_value' => 150000,
          'current_value' => 5000,
          'pitch_deck' => [
            'http://localhost:9292/user/1/100/slide1.png',
            'http://localhost:9292/user/1/100/slide2.png',
            'http://localhost:9292/user/1/100/slide3.png'
          ]
        }
      ]
    }.to_json

    [200, {'Content-Type': 'application/json'}, payload]
  end

  # Create a new pitch deck for user and return metadata
  post '/pitch/:userid' do
    puts params[:userid]
    # requires Authorization header with Bearer token
    # pdf, ppt, psd, ai
    #
    # For POC we will assume that the token is for the correct user and has the correct claims.
    #
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