gem 'oauth'
require 'oauth'
require 'oauth/consumer'
require 'json'

class UsersController < ApplicationController  
  # OAuth configuration for twitter
  CONSUMER_KEY = 'OYo3742Wk6d61JlnVa2Gsw'
  CONSUMER_SECRET = '7cmYNPoAPFyM8UWmXbElzqmbwV2gc8fMsC9d4wHt9w'
  CREDENTIALS_URL = '/account/verify_credentials.json'
  FOLLOWING_URL = 'http://api.twitter.com/1/statuses/friends.json?cursor=%s'
  UNFOLLOW_URL = 'http://api.twitter.com/1/friendships/destroy/%s.json'
  
  def self.consumer
    OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_SECRET, {:site => 'http://twitter.com'})
  end
  
  def access_token
    user_id = session['id']
    user = User.find_by_id(user_id) if user_id
    OAuth::AccessToken.new(UsersController.consumer, user.token, user.secret) if user
  end

  def serialize(msg)
    respond_to do |format|
      format.json { render :json => msg }
      format.xml { render :xml => msg }
    end
  end
  
  def error_response(status_code, message)
    response = { :status => status_code }
    msg = {
      'type' => 'error',
      'message' => message
    }
    
    respond_to do |format|
      format.json { response.merge!(:json => msg) }
      format.xml { response.merge!(:xml => msg) }
    end
    
    render response
  end

  # GET /api/following
  def following
    access_token = self.access_token
    consumer = UsersController.consumer
    
    unless access_token
      callback_url = '%s%s/api/auth' % [request.protocol, request.host_with_port]
      request_token = consumer.get_request_token(:oauth_callback => callback_url)
      session['request_token'] = request_token

      return self.serialize({
        'type' => 'redirect',
        'redirect' => request_token.authorize_url,
        'errorMessage' => flash['error_message']
      })
    end

    cursor = -1
    users = []
    
    while cursor != 0
      url = FOLLOWING_URL % cursor
      response = consumer.request(:get, url, access_token, { :scheme => :query_string })
      
      if response.class != Net::HTTPOK
        return error_response(400, 'Could not fetch users')
      end
      
      json = JSON.parse(response.body)
      cursor = json['next_cursor']
      
      json['users'].each do |user|
        status = user['status']['text'] if user.has_key?('status')
        users.push({
          'profileImage' => user['profile_image_url'],
          'screenName' => user['screen_name'],
          'verified' => user['verified'],
          'status' => status
        })
      end
    end
    
    self.serialize({
      'type' => 'results',
      'users' => users
    })
  end
  
  # GET /api/auth
  def auth
    request_token = session['request_token']
    access_token = request_token.get_access_token({:oauth_verifier => params[:oauth_verifier]})
    response = UsersController.consumer.request(:get, CREDENTIALS_URL, access_token, { :scheme => :query_string })
    error = response.class == Net::HTTPSuccess
    
    if not error
      user = User.new({
        :token => access_token.token,
        :secret => access_token.secret
      })
      
      user.save!
      session['id'] = user.id
    end
    
    flash['error_message'] = 'Failed to authenticate' if error
    redirect_to '/'
  end
  
  #PUT /api/unfollow
  def unfollow
    access_token = self.access_token
    consumer = UsersController.consumer
    users = params[:users].split(',')
    
    users.each do |user|
      response = consumer.request(:delete, UNFOLLOW_URL % user, access_token, { :scheme => :query_string })
      
      if response.class != Net::HTTPOK
        return error_response(400, 'Could not unfollow users')
      end
    end
    
    self.serialize({
      'type' => 'unfollowed',
      'users' => users
    })
  end
end