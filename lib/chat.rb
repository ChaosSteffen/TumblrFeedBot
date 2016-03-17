# frozen_string_literal: true
class Chat
  def start
    Datastore.open_chat id

    reply 'Welcome to the TumblrFeedBot!'
  end

  def stop
    Datastore.close_chat id

    reply 'Thank you for using the TumblrFeedBot!'
  end

  def list_subscriptions
    blogs = Datastore.blog_names_for_chat id

    reply "You are subscribed to:\n#{blogs * "\n"}"
  end

  def add_subscription(blog_identifier)
    client = Tumblr::Client.new
    response = client.blog_info(blog_identifier)

    if response['status'] == 404
      reply "Unable to subscribe to \"#{blog_identifier}\". Unknown tumblr!"
    else
      number_of_posts = response['blog']['posts']

      Datastore.add_subscription id, blog_identifier, number_of_posts

      list_subscriptions
    end
  end

  def remove_subscription(blog_identifier)
    Datastore.remove_subscription id, blog_identifier

    reply 'You are unsubscribed now!'
  end

  def remove_all_subscriptions
    Datastore.remove_all_subscriptions id

    reply 'You are unsubscribed from all feeds now!'
  end
end
