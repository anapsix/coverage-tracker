#!/usr/bin/env ruby

require 'bundler'
Bundler.require(:default)

configure do
  set :redis_host, ENV['REDIS_HOST'] || '127.0.0.1'
  set :redis_port, ENV['REDIS_PORT'] || '6379'

  set :default_branch, ENV['DEFAULT_BRANCH'] || 'master'

  set :badge_prefix, ENV['BADGE_PREFIX'] || 'coverage'
  set :coverage_high, ENV['COVERAGE_HIGH'] || 75.00
  set :coverage_low, ENV['COVERAGE_LOW'] || 30.00

  set :shields_default_fileformat, ENV['SHIELDS_DEFAULT_FILEFORMAT'] || 'svg'
  set :shield_default_style, ENV['SHIELDS_DEFAULT_STYLE'] || 'for-the-badge'

  set :views, [ File.expand_path('../', __FILE__) ]
  mime_type :md, 'text/plain'
end

$redis = Redis.new(host: settings.redis_host, port: settings.redis_port, db: 0)

def get(repo=nil, branch="default")
  return nil if repo.empty? || repo.nil?
  return $redis.get("#{repo}:#{branch}")
end

def set(repo=nil, branch="default", value=nil)
  return nil if repo.empty? || repo.nil? || value.empty? || value.nil?
  return $redis.set("#{repo}:#{branch}", value)
end


## routes below

get '/' do
  markdown :README
end

get '/:repo/?:branch?' do |repo, branch=nil|
  branch = settings.default_branch unless branch
  query = Rack::Utils.parse_nested_query(request.query_string) || {}
  lookup = get(repo, branch)

  if query['shields'].to_s[/yes|on|true|1/]
    style = query['style'] || settings.shield_default_style
    fileformat = query['fileformat'] || settings.shields_default_fileformat
    low = query['low'] ? query['low'].to_f : settings.coverage_low
    high = query['high'] ? query['high'].to_f : settings.coverage_high
    color = lookup.to_f <= low ? "red" : lookup.to_f >= high ? 'green' : 'yellow'
    prefix = query['prefix'].to_s[/no|off|false|0/] ? '' : query['prefix'] || settings.badge_prefix
    debug = query['debug']

    # nil lookup means coverage was never
    # recorded for this :repo/:branch
    if lookup.nil?
      lookup = "0"
      color = "lightgrey"
    end

    return {
      :coverage => lookup.to_f,
      :low => low,
      :high => high,
      :color => color,
      :prefix => prefix
    }.to_s if debug.to_s[/yes|on|true|1/]

    redirect "https://img.shields.io/badge/#{prefix}-#{lookup}%25-#{color}.#{fileformat}?style=#{style}", 302
  elsif lookup.nil?
      status 404
      return "no recorded coverage for #{repo}/#{branch}"
  else
    return lookup
  end
end

post '/:repo/?:branch?' do |repo, branch=nil|
  branch = settings.default_branch unless branch
  # puts "BRANCH is \"#{branch}\""
  coverage = JSON.parse(request.body.read)['coverage']
  set(repo, branch, coverage)
end

get '/*' do
  status 404
  "### 404 ###"
end

