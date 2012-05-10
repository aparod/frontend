class AMQPTools

  class << self

    def rpc(message)
      raise "Message must be a hash." unless message.is_a? Hash

      b1 = Bunny.new
      b1.start

      reply_queue = b1.queue

      reply_thread = Thread.new do
        reply_queue.subscribe(:timeout => 15, :message_max => 1) do |msg|
          reply_thread[:payload] = JSON.parse msg[:payload], :symbolize_names => true
        end
      end

      b2 = Bunny.new
      b2.start

      e = b2.exchange('')
      e.publish(
        message.to_json,
        :key            => "testqueue",
        :reply_to       => reply_queue.name,
        :correlation_id => Kernel.rand(10101010).to_s,
        :mandatory      => true,
        :immediate      => true
      )

      reply_thread.join

      b1.stop
      b2.stop

      payload = reply_thread[:payload]

      raise "Error getting response to message." unless payload
      raise "RPC Error: #{payload[:data]}" if payload[:error]

      payload[:data]
    end

  end

end
