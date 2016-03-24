# coding: utf-8
require 'yaml'
require 'twitter'
require 'docomoru'

class Bot
  attr_accessor :client, :timeline
  def initialize
    env = YAML.load_file('./config.yml')
    timeline = Twitter::Streaming::Client.new do |config|
      config.consumer_key        = env['consumer_key']
      config.consumer_secret     = env['consumer_secret']
      config.access_token        = env['access_token']
      config.access_token_secret = env['access_token_secret']
    end

    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = env['consumer_key']
      config.consumer_secret     = env['consumer_secret']
      config.access_token        = env['access_token']
      config.access_token_secret = env['access_token_secret']
    end

    @timeline = timeline
    @client = client
  end

  def post(msg = '', tw_id: nil, status_id: nil)
    if status_id
      rep_msg = "@#{tw_id} #{msg}"
      @client.update(rep_msg, {in_reply_to_status_id: status_id})
      puts "#{rep_msg}"
    else
      @client.update(msg)
      puts "#{msg}"
    end
  end
end

class ReplyEngine
  def initialize(text='', params={})
    @opts = params
    @text = text
    env = YAML.load_file('./config.yml')
    @client = Docomoru::Client.new(api_key: env["docomo_api_key"])
  end

  def result
    @client.create_dialogue(@text, @opts)
  end
end

@response_cache = {context: '', mode: ''}
bot = Bot.new
begin
  bot.timeline.user do |tw|
    case tw
    when Twitter::Tweet
      text = tw.text
      twitter_id = tw.user.screen_name
      status_id = tw.id
      # Not RT and only reply to @korot0ro
      if !text.index("RT")
        if text.match(/^@korot0ro/)

          Thread.new do
            sleep 2
            rep_engine = ReplyEngine.new(text.sub(/^@korot0ro /,''), @response_cache)
            @result = rep_engine.result
            @response_cache[:context] = @result.body["context"]
            @response_cache[:mode] = @result.body["mode"]

            reply_msg = @result.body["utt"]
            bot.post(reply_msg, tw_id: twitter_id, status_id: status_id)
          end

        end
      end
    end
  end
rescue => e
  puts "#{Time.now}: #{e}"
  sleep 3
  retry
rescue Interrupt
  exit 1
end
