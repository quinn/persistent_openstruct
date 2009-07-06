require 'rubygems'
require 'digest/md5'
require 'ostruct'
require 'pathname'
require 'uuid'

require File.dirname(__FILE__) + '/moneta-0.6.1/lib/moneta'
require File.dirname(__FILE__) + '/moneta-0.6.1/lib/moneta/file'
require File.dirname(__FILE__) + '/moneta-0.6.1/lib/moneta/rufus'

class PersistentOpenStruct < OpenStruct
  attr_accessor :key, :storage
  
  def initialize *args
    super
    self.class.identity_map[key] = self
  end
  
  def self.storage
    @storage ||= eval(config[:storage_class]).new config[:storage_config]
  end
  
  def self.config
    config = YAML::load File.read( File.expand_path('spec/storage_config.yml') )
    @config = config[self.to_s] || config['PersistentOpenStruct']
  end
  
  def new_ostruct_member(name)
    name = name.to_sym
    unless self.respond_to?(name)
      meta = class << self; self; end
      meta.send(:define_method, name) { @table[name] }
      meta.send(:define_method, :"#{name}=") do |x| 
        @table[name] = x
        save
      end
    end
  end
  
  def method_missing(mid, *args) # :nodoc:
    mname = mid.id2name
    len = args.length
    if mname =~ /=$/
      if len != 1
        raise ArgumentError, "wrong number of arguments (#{len} for 1)", caller(1)
      end
      if self.frozen?
        raise TypeError, "can't modify frozen #{self.class}", caller(1)
      end
      mname.chop!
      self.new_ostruct_member(mname)
      send "#{mname}=", args[0] # this line added
      # @table[mname.intern] = args[0] # this line removed from ostruct
    elsif len == 0
      @table[mid]
    else
      raise NoMethodError, "undefined method `#{mname}' for #{self}", caller(1)
    end
  end
  
  def key
    @key ||= UUID.generate
  end
  
  def save
    self.class.storage[key] = self
    self
  end
  
  def self.identity_map
    @identity_map ||= {}
  end
  
  def self.find key
    return identity_map[key] if identity_map[key]
    found = storage[key]
    identity_map[key] = found if found
    found
  end
end
