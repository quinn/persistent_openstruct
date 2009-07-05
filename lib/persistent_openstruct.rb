require 'rubygems'
require 'moneta-0.6.1/lib/moneta'
require 'moneta-0.6.1/lib/moneta/file'
require 'digest/md5'
require 'ostruct'
require 'pathname'
require 'uuid'

class PersistentOpenStruct < OpenStruct
  attr_accessor :key, :storage
  
  def initialize storage, key = nil, hash = nil
    @storage = storage
    @key = key
    @table = {}
    if hash
      for k,v in hash
        @table[k.to_sym] = v
        new_ostruct_member(k)
      end
    end
  end
  
  def save
    storage[key] = self
    self
  end
end
