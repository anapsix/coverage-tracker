#!/usr/bin/env ruby

ENV['RACK_ENV'] = 'test'
ENV['REDIS_HOST'] = '127.0.0.1'
ENV['REDIS_PORT'] = '6379'
ENV['DEFAULT_BRANCH'] = 'default_branch'

require File.expand_path('../../main.rb', __FILE__)
Bundler.require(:default, :test)

class CoverageTrackerTest < Test::Unit::TestCase
  include Rack::Test::Methods

  $repo_unknown = "unknown-repo"
  $repo = "myrepo"
  $branch = "mybranch"
  $branch_default = ENV['DEFAULT_BRANCH']

  class << self
    def startup
      unless ENV['REDIS_NO_START'] == '1'
        redis = fork do
          exec "redis-server --pidfile redis.pid > /dev/null"
        end
        Process.detach(redis)
      end
    end

    def shutdown
      unless ENV['REDIS_NO_START'] == '1'
        pid = File.read('redis.pid').chomp
        system("kill #{pid} 2>&1 >/dev/null")
      end
    end
  end

  def random_string(length=10)
    o = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten
    (0...length).map { o[rand(o.length)] }.join
  end

  def app
    Sinatra::Application
  end

  def test_it_says_hello_world
    get '/'
    assert last_response.ok?
  end

  def test_favicon_404
    get '/favicon.ino'
    assert_equal 404, last_response.status
  end

  def test_random_404
    10.times do
      get "/#{random_string()}"
      assert_equal 404, last_response.status
    end
  end

  def test_getting_unknown
    get "/#{$repo_unknown}/#{$branch_default}"
    assert_equal 404, last_response.status
    assert_equal "no recorded coverage for #{$repo_unknown}/#{$branch_default}", last_response.body
  end

  def test_repo_no_slash
    post "/#{$repo}", '{"coverage":"11.11"}'
    assert last_response.ok?
    assert_equal "OK", last_response.body

    get "/#{$repo}"
    assert_equal "11.11", last_response.body
  end

  def test_repo_slash
    post "/#{$repo}/", '{"coverage":"22.22"}'
    assert last_response.ok?
    assert_equal "OK", last_response.body

    get "/#{$repo}/"
    assert_equal "22.22", last_response.body
  end

  def test_repo_default_branch
    post "/#{$repo}/#{$branch_default}", '{"coverage":"33.33"}'
    assert last_response.ok?
    assert_equal "OK", last_response.body

    get "/#{$repo}/#{$branch_default}"
    assert_equal "33.33", last_response.body
  end

  def test_repo_altogether
    post "/#{$repo}", '{"coverage":"11.11"}'
    assert last_response.ok?
    assert_equal "OK", last_response.body

    post "/#{$repo}/", '{"coverage":"22.22"}'
    assert last_response.ok?
    assert_equal "OK", last_response.body

    post "/#{$repo}/#{$branch_default}", '{"coverage":"33.33"}'
    assert last_response.ok?
    assert_equal "OK", last_response.body

    get "/#{$repo}"
    assert_equal "33.33", last_response.body

    get "/#{$repo}/"
    assert_equal "33.33", last_response.body

    get "/#{$repo}/#{$branch_default}"
    assert_equal "33.33", last_response.body
  end

  def test_NaN
    post "/#{$repo}", '{"coverage":"NaN"}'
    assert last_response.ok?
    assert_equal "OK", last_response.body

    get "/#{$repo}"
    assert_equal "0.0", last_response.body
  end

end
