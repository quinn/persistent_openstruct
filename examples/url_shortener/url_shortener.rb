require '../../lib/persistent_openstruct'
require 'addressable/uri'
require 'sinatra'

PersistentOpenStruct.config_file = 'storage_config.yml'

set :reload => true
class Url < PersistentOpenStruct
  Chars= "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789" unless defined?(Chars)
  
  attr_accessor :key
  
  def self.create target
    length = storage['length'] ||= 0
    short = ""
    url = new
    while (i||=length+1) > 0
      offset = i % Chars.length
      offset = Chars.length if offset == 0
      short.insert 0, Chars[offset-1].chr
      i= (i-offset) / Chars.length
    end
    storage['length'] += 1
    url.key = short
    url.target = target
    url
  end
end

get('/:short') { (url = Url.find(params[:short])) ? redirect(url.target) : status(404) }
get('/')     { haml(:index) }
post '/' do
  target = Addressable::URI.heuristic_parse(params["url"]).to_s
  @url = Url.create(target)
  haml :index
end

__END__
@@ index
!!! Strict
%html{html_attrs("en")}
  %head
    %meta{"http-equiv"=>"content-type",:content=>"text/html; charset=utf-8"}
    %meta{:name=>"author",:content=>"Belighted + Deaxon"}
    %title i5 | Simple URL shortener
    %script{:type=>"text/javascript"}
      window.onload = function() { document.getElementsByTagName('input')[0].focus() }
    %style{:type=>"text/css",:media=>"screen"}
      body { font:.8em/1.5 "lucida grande", "lucida sans", "luxi sans", "lucida sans unicode", arial, sans-serif; padding:50px; }
      h1 { border-bottom:1px solid #ddd; max-width:500px; margin-bottom:1em; }
      em { font-style:normal; font-weight:400; color:#777; }
      input:first-child { width:200px; margin-right:3px; padding:2px 0; }
      form+p { max-width:480px; font-size:2.5em; letter-spacing:-1px; background:#ffff77; padding:10px; }
  %body
    %h1== i5 | <em>Simple URL shortener</em>
    %form{:action=>"/",:method=>"post"}
      %p
        %input{:name=>"url", :title=>"URL to compress"}
        %input{:type=>"submit", :value=>"Compress"}
    - if @url
      %p= "http://i5.be/#{@url.key}"
