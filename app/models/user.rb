class User

  def self.method_missing(name, *args)
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

  def self.from_json(json)
    obj = self.new
    json.each { |key, value| obj.send "#{key}=", value }
    obj
  end

  def initialize
    @@attrs ||= AMQPTools.rpc(
      :class_name  => self.class.name,
      :method_name => :attribute_names,
      :method_args => nil
    )
    self.class.send :attr_accessor, *@@attrs
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

end
