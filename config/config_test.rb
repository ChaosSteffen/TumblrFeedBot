# frozen_string_literal: true
require './config/config'

TEST_DB = 1
Datastore.redis.select TEST_DB
