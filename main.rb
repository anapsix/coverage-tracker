require 'json'
require 'redis'
require 'sinatra'

configure do
  set :redis_host, ENV['REDIS_HOST'] || '127.0.0.1'
  set :redis_port, ENV['REDIS_PORT'] || '6379'
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

get '/:repo/:branch?' do |repo, branch="master"|
  query = Rack::Utils.parse_nested_query(request.query_string) || {}
  lookup = get(repo, branch)
  if lookup.nil?
    status 404
    return
  end
  if query['shields'] == 'true'
    style = query['style'] || 'for-the-badge'
    fileformat = query['fileformat'] || 'svg'
    low = query['low'].to_f || 30.0
    high = query['high'].to_f || 75.0
    color = lookup.to_f <= low ? "red" : lookup.to_f >= high ? "green" : "yellow"
    redirect "https://img.shields.io/badge/coverage-#{lookup}%25-#{color}.#{fileformat}?style=#{style}", 302
  else
    return lookup
  end
end

post '/:repo/:branch?' do |repo, branch="master"|
  coverage = JSON.parse(request.body.read)['coverage']
  set(repo, branch, coverage)
end

