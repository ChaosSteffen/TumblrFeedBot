# frozen_string_literal: true
describe App do
  before do
    Telegram.stubs(:path_verified).returns(true)
    Telegram.stubs(:sendMessage)

    @redis = Datastore.redis
    @redis.flushdb
  end

  after do
    @redis.flushdb
  end

  def json_for_message(text)
    {
      'update_id' => rand(100_000_000),
      'message' => {
        'message_id' => rand(100),
        'chat' => {
          'id' => rand(1_000_000_000),
          'first_name' => 'Foo',
          'last_name' => 'Bar',
          'username' => 'FooBar',
          'type' => 'private'
        },
        'date' => rand(10_000_000_000),
        'text' => text
      }
    }
  end

  it 'starts a new chat' do
    replace_app(App.new) do
      Datastore.expects(:open_chat)

      post_json '/', json_for_message('/start')
    end
  end

  it 'stops a chat' do
    replace_app(App.new) do
      Datastore.expects(:close_chat)

      post_json '/', json_for_message('/stop')
    end
  end

  it 'delivers a help message' do
    replace_app(App.new) do
      Telegram.expects(:sendMessage)

      post_json '/', json_for_message('/help')
    end
  end

  it 'lists subscriptions' do
    replace_app(App.new) do
      chat_id = rand(1_000_000_000)
      Datastore.add_subscription chat_id, 'test-blog1', rand(10)
      Datastore.add_subscription chat_id, 'test-blog2', rand(10)

      update = json_for_message('/list')
      update['message']['chat']['id'] = chat_id

      Telegram.expects(:sendMessage).with do |param|
        assert param[:text].include?('test-blog1')
        assert param[:text].include?('test-blog2')
      end

      post_json '/', update
    end
  end

  it 'adds a subscription for a tumblr blog' do
    replace_app(App.new) do
      fake_client = stub(blog_info: { 'blog' => { 'posts' => 5 } })
      Tumblr::Client.stubs(:new).returns(fake_client)

      Telegram.expects(:sendMessage).with do |param|
        assert param[:text].include?('my-super-blog')
      end

      update = json_for_message('/follow my-super-blog')

      post_json '/', update
    end
  end

  it 'removes subscriptions for a blog' do
    replace_app(App.new) do
      update = json_for_message('/unfollow my-super-blog')
      chat_id = update['message']['chat']['id']

      Datastore.expects(:remove_subscription).with do |id, blog_identifier|
        assert_equal id, chat_id
        assert_equal blog_identifier, 'my-super-blog'
      end
      Telegram.expects(:sendMessage)

      post_json '/', update
    end
  end

  it 'removes all blog subscriptions' do
    replace_app(App.new) do
      update = json_for_message('/unfollow_all')
      chat_id = update['message']['chat']['id']

      Datastore.expects(:remove_all_subscriptions).with do |id|
        assert_equal id, chat_id
      end
      Telegram.expects(:sendMessage)

      post_json '/', update
    end
  end

  it 'sanitizes blog names' do
    app = App.new
    assert_equal app.sanitize_blog_identifier('HttP://Foo-Bar-Blog.tumblr.com'), 'foo-bar-blog.tumblr.com'
    assert_equal app.sanitize_blog_identifier('faraway-gs'), 'faraway-gs'
  end

  it 'implements a loop' do
    app = App.new
    assert app.respond_to?(:loop)
  end

  it 'checks all blogs for new updates' do
    app = App.new

    chat_id = rand(1_000_000_000)
    blog_identifier = 'my-super-blog'
    number_of_posts = rand(100)

    Datastore.add_subscription(chat_id, blog_identifier, number_of_posts)

    app.expects(:notify_if_new).with(chat_id, blog_identifier, number_of_posts)
    app.loop
  end

  it 'send notifications if new blog update' do
    app = App.new

    chat_id = rand(1_000_000_000)
    blog_identifier = 'my-super-blog'
    number_of_posts = rand(100)

    new_post_summary = 'foo'
    new_post_url =  'http://foo.bar'

    Datastore.add_subscription(chat_id, blog_identifier, number_of_posts)

    fake_client = mock
    fake_client.stubs(blog_info: { 'blog' => { 'posts' => number_of_posts + 1 } })
    fake_client.stubs(posts: { 'posts' => [{ 'summary' => new_post_summary, 'post_url' => new_post_url }] })
    Tumblr::Client.expects(:new).returns(fake_client)

    Telegram.expects(:sendMessage).with do |param|
      assert_equal param[:chat_id], chat_id
      assert param[:text].include?(new_post_summary)
      assert param[:text].include?(new_post_url)
    end

    Datastore.expects(:update_subscription).with(chat_id, blog_identifier, number_of_posts + 1)

    app.notify_if_new(chat_id, blog_identifier, number_of_posts)
  end
end
