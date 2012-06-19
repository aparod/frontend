module Stub

  def self.included receiver
    receiver.extend ClassMethods
  end

  module ClassMethods

    def get_attribute_names
      @attrs ||= AMQPTools.rpc(
        :class_name  => self.name,
        :method_type => :class,
        :method_name => :attribute_names,
        :method_args => nil
      )
    end

    def method_missing(name, *args)
      data = AMQPTools.rpc(
        :class_name  => self.name,
        :method_type => :class,
        :method_name => name,
        :method_args => args
      )

      process data
    end

    def process(data)
      if data.is_a? Array
        data.map do |e|
          process e
        end
      elsif data.is_a? Hash
        build data
      else
        data
      end
    end

    def build(hash)
      class_name = hash.keys.first
      class_data = hash[class_name]
      klass      = class_name.to_s.camelcase.constantize

      obj = klass.new
      class_data.each { |key, value| obj.send "#{key}=", value }
      obj
    end

  end

  def initialize
    self.class.send :attr_accessor, *self.class.get_attribute_names
  end

  def method_missing(name, *args)
    data = AMQPTools.rpc(
      :class_name   => self.class.name,
      :method_type  => :instance,
      :method_name  => name,
      :method_args  => args,
      :object_state => self.to_hash
    )

    root_node = data[:object_state].keys.first
    data[:object_state][root_node].each { |key, value| send "#{key}=", value }

    self.class.process data[:return_value]
  end

  def to_hash
    hash = {}

    instance_variables.each do |var|
      hash[var[1..-1].to_sym] = instance_variable_get(var)
    end

    hash
  end

  def local
    nil
  end

end
