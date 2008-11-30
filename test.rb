require 'lib/proxy'

p = Proxy.new("http://arstechnica.com")
response = p.get_from_origin('/index.ars')

response.header.each do |k,v|
  puts "#{k}: #{v}"
end

template = %q{
<p><%= 
  dynamic do |req|
    {:url => 'http://arstechnica.com/index.ars'}
  end
%></p>
}

htemplate = %q{
%p
  =dynamic do |req|
    -{:url => 'http://arstechnica.com/index.ars'}
}

puts p.process(:erb,template)
#puts p.process(:haml, htemplate)