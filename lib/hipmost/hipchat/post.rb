require 'date'

require_relative "conversion"

module Hipmost
  module Hipchat
    class Post
      def initialize(attrs, room, is_private_room)
        @private    = is_private_room
        @attrs      = attrs
        @sender     = Hipchat.users[attrs["sender"]["id"]]
        @message    = attrs["message"].gsub("\\", "\\\\\\")
        @created_at = DateTime.strptime(attrs["timestamp"])
        @team       = room.team
        @channel    = room.channel
        if is_private_room
          @receiver = Hipchat.users[attrs["sender"]["id"]]
        end
      end
      attr_reader :team, :channel, :sender

      def to_jsonl
        # First, convert Hipchat formatting to markdown...
        Conversion.convert_formatting_to_markdown(@message)

        # Then, generate the actual object based on whether the room is private or not.
        if @private
          members = [@sender.username, @receiver.username].sort
          %[{ "type": "direct_post", "direct_post": { "channel_members": #{members.inspect}, "user": "#{@sender.username}", "message": #{JSON.dump(@message)}, "create_at": #{@created_at.to_time.to_i*1000} } }]
        else
          %[{ "type": "post", "post": { "team": "#{team.name}", "channel": "#{channel.name}", "user": "#{sender.username}", "message": #{JSON.dump(@message)}, "create_at": #{@created_at.to_time.to_i*1000} } }]
        end
      end
    end
  end
end
