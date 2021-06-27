require "minitest/autorun"
require 'rack/test'
require_relative '../application_controller'
require_relative 'test_helper'

class ApplicationControllerTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    super
    @controller = ApplicationController.new
    @app = Rack::Test::Session.new(Rack::MockSession.new(ApplicationController.new))
  end

  def test_root_path
    @app.header 'ORIGIN', 'http://localhost:8080'
    @app.get('/')

    assert_equal 'http://localhost:8080', @app.last_response.headers['Access-Control-Allow-Origin']
    assert_equal 'GET, POST, PATCH, OPTIONS', @app.last_response.headers['Access-Control-Allow-Methods']
  end

end