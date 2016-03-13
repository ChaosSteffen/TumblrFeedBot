# frozen_string_literal: true
Tumblr.configure do |config|
  config.consumer_key = ENV['TUMBLR_CONSUMER_KEY']
  config.consumer_secret = ENV['TUMBLR_CONSUMER_SECRET']
end

Telegram.token = ENV['TELEGRAM_TOKEN']

Datastore.redis = Redis.new
