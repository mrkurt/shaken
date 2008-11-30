require 'rubygems'
require 'rack'
require 'uri'
require 'net/http'

if $0 == __FILE__
  require 'rack'
  require 'rack/showexceptions'
  Rack::Handler::WEBrick.run \
    Rack::ShowExceptions.new(Rack::Lint.new(Proxy.new)),
    :Port => 9292
end