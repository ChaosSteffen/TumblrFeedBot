# frozen_string_literal: true

# Main App
class App < Bot
  on :start do |update|
    update.message.chat.start
  end

  on :stop do |update|
    update.message.chat.stop
  end

  on :help do |update|
    text = %q(This is the TumblrFeedBot.
You can use it to follow tumblr blogs and get the latest post in directly to you.
You can use the following commands:

/follow <i>name_of_tumblr_blog</i>
/unfollow <i>name_of_tumblr_blog</i>
/unfollow_all
/list
)

    update.message.chat.reply(text, parse_mode: 'HTML')
  end

  on :list do |update|
    update.message.chat.list_subscriptions
  end

  on :follow do |update|
    _, blog_identifier, = update.message.text.split(' ')
    blog_identifier = sanitize_blog_identifier blog_identifier

    update.message.chat.add_subscription blog_identifier
  end

  on :unfollow do |update|
    _, blog_identifier, = update.message.text.split(' ')
    blog_identifier = sanitize_blog_identifier blog_identifier

    update.message.chat.remove_subscription blog_identifier
  end

  on :unfollow_all do |update|
    update.message.chat.remove_all_subscriptions
  end

  def loop
    Datastore.all_subscribers.each do |chat_id|
      blogs = Datastore.blogs_for_chat chat_id

      blogs.each do |blog_identifier, number_of_posts|
        notify_if_new chat_id, blog_identifier, number_of_posts
      end
    end
  end

  def sanitize_blog_identifier(string)
    string = string.downcase
    string.start_with?('http') ? URI(string).host : string
  end

  def notify_if_new(chat_id, blog_identifier, number_of_known_posts)
    client = Tumblr::Client.new
    response = client.blog_info(blog_identifier)

    unless response['status'] == 404
      number_of_posts = response['blog']['posts']

      if number_of_posts > number_of_known_posts
        number_of_new_posts = number_of_posts - number_of_known_posts
        response = client.posts(blog_identifier, limit: number_of_new_posts)

        response['posts'].reverse_each do |post|
          summary = post['summary']
          url = post['post_url']

          Telegram.sendMessage(chat_id: chat_id, text: "#{summary}\n#{url}")
        end

        Datastore.update_subscription chat_id, blog_identifier, number_of_posts
      end
    end
  end
end
