# frozen_string_literal: true
require 'net/http'
require 'json'
require 'redis'

require 'tumblr_client'

Dir['./lib/**/*.rb'].each { |file| require file }
Dir['./app/**/*.rb'].each { |file| require file }
