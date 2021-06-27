require "minitest/autorun"
require 'rack/test'
require_relative '../application_controller'
require_relative '../lib/woowoo_token_validation'
require_relative 'test_helper'

class ApplicationControllerTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    super
    @controller = ApplicationController.new
    @app = Rack::Test::Session.new(Rack::MockSession.new(ApplicationController.new))
    @sample_user = 'user@goat.com'
    @sample_data = '{"user@goat.com":[{"id":1,"name":"Sample Campaign","snippet":"Lorem ipsum dolor sit amet.","goal_value":150000,"current_value":5000,"thumbnail":"http://localhost:9292/api/static/placeholder.png","pitch_deck":[{"width":800,"height":600,"url":"http://localhost:9292/api/static/placeholder.png"},{"width":800,"height":600,"url":"http://localhost:9292/api/static/placeholder.png"},{"width":800,"height":600,"url":"http://localhost:9292/api/static/placeholder.png"}]}]}'
  end

  def test_root_path
    @app.header 'ORIGIN', 'http://localhost:8080'
    @app.get('/')

    assert_equal 'http://localhost:8080', @app.last_response.headers['Access-Control-Allow-Origin']
    assert_equal 'GET, POST, PATCH, OPTIONS', @app.last_response.headers['Access-Control-Allow-Methods']
  end

  def test_root_path_with_random_origin
    @app.header 'ORIGIN', 'http://someweirdsite.com'
    @app.get('/')

    assert_nil @app.last_response.headers['Access-Control-Allow-Origin']
    assert_nil @app.last_response.headers['Access-Control-Allow-Methods']
  end

  def test_pitch_endpoint_without_token
    @app.header 'ORIGIN', 'http://someweirdsite.com'
    @app.get('/pitch/100')

    assert_nil @app.last_response.headers['Access-Control-Allow-Origin']
    assert_nil @app.last_response.headers['Access-Control-Allow-Methods']

    json = JSON.parse(@app.last_response.body)

    assert_equal ["Request requires a token."], json["errors"]
    assert_nil json["data"]
  end

  def test_pitch_endpoint_with_valid_token
    WooWooFund::TokenValidation.expects(:validate).with('abc').returns({
                                                                         :status_code => 1,
                                                                         :status_text=>"VALID",
                                                                         :payload => {
                                                                           "user" => {
                                                                             "email" => @sample_user
                                                                           }
                                                                         }
                                                                       })
    File.expects(:read).with('./database.json').returns(@sample_data)

    @app.header 'ORIGIN', 'http://someweirdsite.com'
    @app.get('/pitch/100?token=abc')

    assert_nil @app.last_response.headers['Access-Control-Allow-Origin']
    assert_nil @app.last_response.headers['Access-Control-Allow-Methods']

    json = JSON.parse(@app.last_response.body)

    assert_equal [], json["errors"]
    assert_equal 1, json["data"].length
  end

end