# frozen_string_literal: true
describe Datastore do
  before do
    @redis = Datastore.redis
    @redis.flushdb
  end

  after do
    @redis.flushdb
  end

  let(:chat) { Chat.new(id: rand(100), type: 'private') }
  let(:a_bunch_of_chats) { Array.new(5) { Chat.new(id: rand(100), type: 'private') } }
  let(:a_bunch_of_blogs) { { 'super_blog' => rand(100), 'mega_blog' => rand(100), 'giga_blog' => rand(100) } }

  it 'creates a list of open chats' do
    assert !@redis.exists(:open_chats)
    Datastore.open_chat chat.id
    assert @redis.exists(:open_chats)
  end

  it 'adds a new chat if opened' do
    Datastore.open_chat chat.id
    assert @redis.sismember(:open_chats, chat.id)
  end

  it 'removes a chat when stopped' do
    Datastore.open_chat chat.id
    assert @redis.sismember(:open_chats, chat.id)

    Datastore.close_chat chat.id
    assert !@redis.sismember(:open_chats, chat.id)
  end

  it 'tells all subscribers' do
    a_bunch_of_chats.each do |chat|
      @redis.sadd :subscribers, chat.id
    end
    assert_equal Datastore.all_subscribers.uniq.sort, a_bunch_of_chats.map(&:id).uniq.sort
  end

  it 'tells all blog names for a chat' do
    a_bunch_of_blogs.each do |name, number_of_posts|
      @redis.hset :"subscriptions_#{chat.id}", name, number_of_posts
    end

    assert_equal Datastore.blog_names_for_chat(chat.id), a_bunch_of_blogs.keys
  end

  it 'tells all blog names and number of posts for a chat' do
    a_bunch_of_blogs.each do |name, number_of_posts|
      @redis.hset :"subscriptions_#{chat.id}", name, number_of_posts
    end

    assert_equal Datastore.blogs_for_chat(chat.id), a_bunch_of_blogs
  end

  it 'adds a subscription' do
    blog_name, number_of_posts = a_bunch_of_blogs.first
    Datastore.add_subscription chat.id, blog_name, number_of_posts

    assert @redis.sismember(:subscribers, chat.id)
    assert_equal @redis.hgetall(:"subscriptions_#{chat.id}"), blog_name => number_of_posts.to_s
  end

  it 'updates a subscription' do
    blog_name, number_of_posts = a_bunch_of_blogs.first

    Datastore.add_subscription chat.id, blog_name, number_of_posts
    assert_equal @redis.hgetall(:"subscriptions_#{chat.id}"), blog_name => number_of_posts.to_s

    number_of_posts += 1

    Datastore.update_subscription chat.id, blog_name, number_of_posts
    assert_equal @redis.hgetall(:"subscriptions_#{chat.id}"), blog_name => number_of_posts.to_s
  end

  it 'removes a subscription' do
    blog_name, number_of_posts = a_bunch_of_blogs.first

    Datastore.add_subscription chat.id, blog_name, number_of_posts
    assert_equal @redis.hgetall(:"subscriptions_#{chat.id}"), blog_name => number_of_posts.to_s

    Datastore.remove_subscription chat.id, blog_name
    assert_equal @redis.hgetall(:"subscriptions_#{chat.id}"), {}
  end

  it 'removes all subscriptions' do
    a_bunch_of_blogs.each do |blog_name, number_of_posts|
      Datastore.add_subscription chat.id, blog_name, number_of_posts
    end

    assert_equal Datastore.blogs_for_chat(chat.id), a_bunch_of_blogs

    Datastore.remove_all_subscriptions chat.id
    assert_equal Datastore.blogs_for_chat(chat.id), {}
  end
end
