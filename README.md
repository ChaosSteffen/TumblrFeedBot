# TumblrFeedBot
[![Build Status](https://travis-ci.org/ChaosSteffen/TumblrFeedBot.svg?branch=master)](https://travis-ci.org/ChaosSteffen/TumblrFeedBot)
[![Code Climate](https://codeclimate.com/github/ChaosSteffen/TumblrFeedBot/badges/gpa.svg)](https://codeclimate.com/github/ChaosSteffen/TumblrFeedBot)

## Prerequisites
- Register your bot to Telegram to get a token (https://core.telegram.org/bots#3-how-do-i-create-a-bot)
- Get a token for tumblr API (https://www.tumblr.com/oauth/apps)

## Installation to Heroku
- Create a new Heroku app
- Add Redis and Scheduler to your Heroku app

```
heroku addons:create scheduler:standard
heroku addons:create redis:default
```
- Set environment variables (telegram and tumblr tokens)

```
heroku config:set TELEGRAM_TOKEN=...
heroku config:set TUMBLR_CONSUMER_KEY=...
heroku config:set TUMBLR_CONSUMER_SECRET=...
```
- Push code to Heroku

```
git push heroku master
```
- Setup Heroku scheduler

```
heroku addons:open scheduler
```
Then add a job that executes ```bin/loop```
- Go chat with your bot
