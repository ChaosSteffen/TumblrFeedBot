# frozen_string_literal: true

# test business logic for chat class
describe Chat do
  before do
    @chat = Chat.new(id: rand(100), type: 'private')

    Net::HTTP.stubs :post_form
    Datastore.redis.flushdb
  end

  after do
    Datastore.redis.flushdb
  end

  it 'it saves the id for every new chat' do
    Datastore.expects(:open_chat).with(@chat.id)

    @chat.start
  end

  it 'welcomes every new chatee' do
    @chat.expects(:reply)

    @chat.start
  end

  it 'removes chats id when chat is closed' do
    Datastore.expects(:close_chat).with(@chat.id)

    @chat.stop
  end

  it 'says goodbye' do
    @chat.expects(:reply)

    @chat.stop
  end

  it 'lists all subscriptions for a chat' do
    Datastore.add_subscription @chat.id, 'foo', rand(10)
    Datastore.add_subscription @chat.id, 'bar', rand(10)

    @chat.expects(:reply).with(includes('foo', 'bar'))
    @chat.list_subscriptions
  end

  it 'adds a subscription' do
    fake_client = stub(blog_info: { 'blog' => { 'posts' => 5 } })
    Tumblr::Client.stubs(:new).returns(fake_client)

    Datastore.expects(:add_subscription).with(@chat.id, 'my-wonderful-blog', 5)

    @chat.add_subscription('my-wonderful-blog')
  end

  it 'adds no subscription for unknown blogs' do
    fake_client = stub(blog_info: { 'status' => 404 })
    Tumblr::Client.stubs(:new).returns(fake_client)

    Datastore.expects(:add_subscription).never

    @chat.add_subscription('my-unknown-blog')
  end

  it 'tells user that blog is unknown' do
    fake_client = stub(blog_info: { 'status' => 404 })
    Tumblr::Client.stubs(:new).returns(fake_client)

    @chat.expects(:reply)

    @chat.add_subscription('my-unknown-blog')
  end

  it 'lists all subscriptions after adding a subscription' do
    fake_client = stub(blog_info: { 'blog' => { 'posts' => 5 } })
    Tumblr::Client.stubs(:new).returns(fake_client)

    @chat.expects(:list_subscriptions)
    @chat.add_subscription('my-wonderful-blog')
  end

  it 'removes a subscription' do
    Datastore.expects(:remove_subscription).with(@chat.id, 'my-wonderful-blog')

    @chat.remove_subscription('my-wonderful-blog')
  end

  it 'notifies user after removing a subscription' do
    @chat.expects(:reply)
    @chat.remove_subscription('my-wonderful-blog')
  end

  it 'removes all subscriptions' do
    Datastore.expects(:remove_all_subscriptions).with(@chat.id)

    @chat.remove_all_subscriptions
  end

  it 'notifies user after removing all subscriptions' do
    @chat.expects(:reply)
    @chat.remove_all_subscriptions
  end
end
