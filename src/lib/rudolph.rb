require 'uri'
require 'net/http'
require 'rexml/document'
require 'sha1'

require 'lib/rudolph/crypt'
require 'lib/rudolph/datastore'
require 'lib/rudolph/http'
require 'lib/rudolph/util'

class Rudolph
  DEBUG         = true
  SYS_USR       = 'Rudolph'
  TWITTER_SRC   = 'rudolph'
  TWITTER_LIMIT = 140
  API_URI       = 'twitter.com'
  VERSION       = '0.2b'

  SQL_TABLE     = "rudolph"

  APP_WIDTH     = 450
  APP_HEIGHT    = 565
  APP_RESIZABLE = false

  UPDT_MARGIN   = 10
  UPDT_CURVE    = 12
  UPDT_PMARGIN  = 10

  MAIN_MARGIN   = 10

  STACKS_WIDTH  = 1.0
  STACKS_MARGIN = 5

  UPDTBOX_HEIGHT  = 100
  MSGSTACK_HEIGHT = 380

  # eggs
  # default is false
  INVERT_TEXT      = false
  # default is twitter.com/
  DEF_PROFILE_PAGE = "http://cursebird.com/"
  # default is hashtags.org/tag/
  DEF_HASHTAG_PAGE = "http://www.hashtags.org/tag/"

  MESSAGES      = {
    :invalid_update_size   => "Your message must have between 2 and 140 chars",
    :authentication_failed => "Authentication failed",
    :server_not_responding => "Server is not responding",
    :invalid_login_pass    => "Either login or password was blank.",
    :could_not_load_theme  => "Couldn't load your preferences. Are you sure your connected to the internet?",
    :network_problem       => "Couldn't connect to the internet",
    :direct_msg_sent       => "Sending direct message to"
  }

  DEF_THEME = { 
    :background     => "#9AE4E8", 
    :text           => "#000000",
    :link           => "#0000FF",
    :sidebar        => "#EEEEEE",
    :sidebar_border => "#DDDDDD",
    :image          => nil, 
    :image_tile     => false
  }

  def self.message key
    MESSAGES[key]
  end
  
  def self.dputs level, message
    send level, Rudolph::Util.time_now + '***' + message
  end
end

# patch for ruby 1.8
if not Object.respond_to? :tap
  class Object
    def tap
      yield self
      self
    end
  end
end