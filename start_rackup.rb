require "rack"

# Allows logging to work in containers.
$stdout.sync = true

Rack::Server.start({ config: 'config.ru', Host:'0.0.0.0', Port: '9292' })
