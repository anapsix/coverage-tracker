require 'rubygems'
require 'json'
require 'redis'
require 'sinatra'
require 'kramdown'

configure do
  set :redis_host, ENV['REDIS_HOST'] || '127.0.0.1'
  set :redis_port, ENV['REDIS_PORT'] || '6379'

  set :coverage_high, ENV['COVERAGE_HIGH'] || 75.00
  set :coverage_low, ENV['COVERAGE_LOW'] || 30.00

  set :shields_default_fileformat, ENV['SHIELDS_DEFAULT_FILEFORMAT'] || 'svg'
  set :shield_default_style, ENV['SHIELDS_DEFAULT_STYLE'] || 'for-the-badge'

  set :views, [ './' ]
  mime_type :md, 'text/plain'
end

$redis = Redis.new(host: settings.redis_host, port: settings.redis_port, db: 0)

def get(repo=nil, branch="master")
  return nil if repo.empty? || repo.nil?
  return $redis.get("#{repo}:#{branch}")
end

def set(repo=nil, branch="master", value=nil)
  return nil if repo.empty? || repo.nil? || value.empty? || value.nil?
  return $redis.set("#{repo}:#{branch}", value)
end


## routes below

get '/' do
  markdown :README
end

get '/:repo/:branch?' do |repo, branch="master"|
  query = Rack::Utils.parse_nested_query(request.query_string) || {}
  lookup = get(repo, branch)
  if lookup.nil?
    status 404
    return "no recorded coverage for #{repo}/#{branch}"
  end
  if query['shields'] == 'true'
    style = query['style'] || settings.shield_default_style
    fileformat = query['fileformat'] || settings.shields_default_fileformat
    low = query['low'] ? query['low'].to_f : settings.coverage_low
    high = query['high'] ? query['high'].to_f : settings.coverage_high
    color = lookup.to_f <= low ? "red" : lookup.to_f >= high ? 'green' : 'yellow'
    debug = query['debug']

    return {
      :low => low,
      :high => high,
      :color => color
    }.to_s if debug && debug.to_s[/yes|on|true|1/]

    redirect "https://img.shields.io/badge/coverage-#{lookup}%25-#{color}.#{fileformat}?style=#{style}", 302
  else
    return lookup
  end
end

post '/:repo/:branch?' do |repo, branch="master"|
  coverage = JSON.parse(request.body.read)['coverage']
  set(repo, branch, coverage)
end

get '/*' do
  status 404
  "### 404 ###"
end

