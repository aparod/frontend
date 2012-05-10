class AMQPTools2

  class << self

    def rpc(message)
      init_thread = Thread.new do
        connection    = AMQP.connect
        channel       = AMQP::Channel.new(connection)
        replies_queue = channel.queue("", :exclusive => true, :auto_delete => true)

        EM.next_tick do
          init_thread[:connection]    = connection
          init_thread[:channel]       = channel
          init_thread[:replies_queue] = replies_queue
          puts "yoyoyo, #{replies_queue.name}"
        end

      end

      init_thread.join
      sleep 2

      @ret           = nil
      @connection    = init_thread[:connection]
      @channel       = init_thread[:channel]
      @replies_queue = init_thread[:replies_queue]

      puts "Name here: #{@replies_queue.name}"

      replies_queue.subscribe do |metadata, payload|
        puts "[response] Response for #{metadata.correlation_id}: #{payload.inspect}"
      end

      sleep 3

      puts "Name here: #{@replies_queue.name}"

#      AMQP.connect do |connection|
#         AMQP::Channel.new(connection) do |channel|
#           puts "channel done"
#           channel.default_exchange.on_return do |basic_return, metadata, payload|
#             puts "#{payload} was returned! reply_code = #{basic_return.reply_code}, reply_text = #{basic_return.reply_text}"
#           end

# #          puts "Creating the reply queue..."
#           AMQP::Queue.new(channel, "", :exclusive => true, :auto_delete => true) do |reply_queue|
# #            puts "Reply queue #{reply_queue.name} is ready to go!"
#             reply_thread = Thread.new do
#               reply_queue.subscribe do |metadata, payload|
# #                puts "[response] Response for #{metadata.correlation_id}: #{payload.inspect}"
#                 ret = payload.inspect
#               end
#             end

#             puts "[request] Sending a request..."
#             puts "Reply queue name: #{reply_queue.name}"

#             channel.default_exchange.publish(
#               {:message => message}.to_json,
#               :routing_key => "testqueue",
#               :correlation_id  => Kernel.rand(10101010).to_s,
#               :reply_to    => reply_queue.name,
#               :immediate   => true
#             )

#           end
#        end
#      end

      puts "end of method"
      ret
    end
  end

end
