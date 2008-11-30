require 'uri'
require 'net/http'
require 'digest/md5'
require 'rubygems'
class Proxy
  attr_accessor :origin

  def initialize(origin)
    origin = URI::parse(origin) if origin.class == String
    self.origin = origin
  end
  def call(env)
    req = Rack::Request.new(env)
    
    res = Rack::Response.new
    uri = URI::parse(req.url)
    res.write("#{req.request_method} for #{origin}#{uri.path}")
    res.finish
  end
  
  def get_from_origin(u, headers = {})
    request_from_origin('get', u, headers)
  end
  
  def process(type, template)
    munged = send("munge_#{type}", template)
    final = munged[:raw]
    munged[:includes].each do |k,v|
      uri = URI::parse(v)
      res = Net::HTTP.start(uri.host, uri.port) {|http|
          http.get(uri.path)
        }
      
      final.sub!(k, res.body)
    end
    final
  end
  
  def munge_haml(template)
    require 'haml'
    engine = Haml::Engine.new(template)
    t = Template.new
    raw = engine.render(t)
    {:raw => raw, :includes => t.get_includes}
  end
  
  def munge_erb(template)
    require 'erb'
    t = Template.new
    erb = ERB.new(template)
    
    raw = t.instance_eval { eval(erb.src) }
    {:raw => raw, :includes => t.get_includes}
  end
  
  protected
  
  def request_from_origin(method, u, headers ={})
    u = URI::parse(u) if u.class == String
    u.host = origin.host
    u.port = origin.port
    u.scheme = origin.scheme  
    
    res = Net::HTTP.start(u.host, u.port) {|http|
        http.send(method, u.path, headers)
      }
  end
end

class Template
  
  def dynamic(url = nil, &b)
    included = b.call(nil) if url.nil?
    url = included[:url] if url.nil?
    key = Digest::MD5.hexdigest(url)
    key = "%%{#{key}}%%"
    register(key, url)
    key
  end
  
  def get_includes
    @includes || {}
  end
  
  protected
  def register(key, url)
    @includes = @includes || {}
    @includes[key] = url
  end
end