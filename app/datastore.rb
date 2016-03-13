# frozen_string_literal: true

# Datastore encapsulates all communication with Redis datastore
module Datastore
  @@redis

  class << self
    attr_accessor :redis
  end

  def self.open_chat(chat_id)
    redis.sadd :open_chats, chat_id
  end

  def self.close_chat(chat_id)
    redis.srem :open_chats, chat_id
  end

  def self.all_subscribers
    redis.smembers(:subscribers).map(&:to_i)
  end

  def self.blog_names_for_chat(chat_id)
    redis.hkeys :"subscriptions_#{chat_id}"
  end

  def self.blogs_for_chat(chat_id)
    Hash[redis.hgetall(:"subscriptions_#{chat_id}").map do |blog_identifier, number_of_posts|
      [blog_identifier, number_of_posts.to_i]
    end]
  end

  def self.add_subscription(chat_id, blog_identifier, number_of_posts)
    redis.sadd :subscribers, chat_id
    redis.hset :"subscriptions_#{chat_id}", blog_identifier, number_of_posts
  end

  def self.update_subscription(chat_id, blog_identifier, number_of_posts)
    redis.hset :"subscriptions_#{chat_id}", blog_identifier, number_of_posts
  end

  def self.remove_subscription(chat_id, blog_identifier)
    redis.hdel :"subscriptions_#{chat_id}", blog_identifier
  end

  def self.remove_all_subscriptions(chat_id)
    redis.del :"subscriptions_#{chat_id}"
  end
end
