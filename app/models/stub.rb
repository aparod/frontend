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

      if data.is_a? Array
        data.map { |e| self.from_json(e) }
      elsif data.nil?
        nil
      else
        self.from_json data
      end
    end

    def from_json(json)
      obj = self.new
      json.each { |key, value| obj.send "#{key}=", value }
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

    data[:object_state].each { |key, value| send "#{key}=", value }

    data[:return_value]
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