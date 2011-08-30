require 'net/http'
require 'net/https'
require 'rubygems'
require 'cgi'
require 'json'
require 'RMagick'
include Magick
require 'sinatra'

get '/twitter' do 
  error 400 if !params[:url]
  content_type 'image/png'
  begin
      get_twitter_stats(params[:url])
  rescue
      get_image('blank', '0', '#ffffff')
  end
end

get '/facebook' do 
  error 400 if !params[:url]
  content_type 'image/png'
  begin
      get_facebook_stats(params[:url])
  rescue
      get_image('blank', '0', '#ffffff')
  end
end

def to_query(params, *parent)
  query = ''
  stack = ''

  params.each do |k, v|
    if v.class == Hash
      parent = k
      stack = v
    else
      query << "#{CGI.escape(k)}=#{CGI.escape(v)}&"
    end
  end
  
  stack.each do |k,v|
    query << "#{CGI.escape(parent)}[#{CGI.escape(k)}]=#{CGI.escape(v)}&"
  end

  return query.chop! 
end

def shortenNumber(number)
  
  case(number.length)
    when 9
      number = number[0, 3] + 'M'
    when 8
      number = number[0, 2] + 'M'
    when 7
      number = number[0, 1] + 'M'
    when 6
      number = number[0, 3] + 'K'
    when 5
      number = number[0, 2] + 'K'
    when 4
      number = number[0, 1] + 'K'
    else
      return number
  end
  
  return number;
  
end

def http_get(domain,path,params)
    path = unless params == ''
        path + "?" + params.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&')
    else
        path
    end
    request = Net::HTTP.get(domain, path)
end

def get_image(media, count, color)
    
    background = ImageList.new(media + '.png')
    canvas = ImageList.new
    canvas.new_image(45, 40, TextureFill.new(background))

    txt = Draw.new
    txt.font_family = 'sans-serif'
    txt.pointsize = 11
    txt.gravity = CenterGravity

    txt.annotate(canvas, 45,35,0,5, shortenNumber(count)){
        self.fill = color
    }

    canvas.format = 'PNG'
    
    return canvas.to_blob
    
end

def get_facebook_stats(url)

    params = {
        :query => 'SELECT total_count FROM link_stat WHERE url = "' + url + '"',
        :format => 'json'
    }

    http = http_get('api.facebook.com', '/method/fql.query', params)
    
    stats = JSON.parse(http[1..-2])
    
    return get_image('facebook', stats['total_count'].to_s, '#000000')

end

def get_twitter_stats(url)
  uri = URI.parse('http://urls.api.twitter.com')

  http = Net::HTTP.new(uri.host, uri.port)

  path = '/1/urls/count.json'

  params = to_query({'url' => url})

  resp, data = http.post(path, params)
  stats = JSON.parse(data)

  return get_image('twitter', stats['count'].to_s, '#00A5E4')
  
end