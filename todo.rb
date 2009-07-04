require 'rubygems'
require 'moneta-0.6.1/lib/moneta'
require 'moneta-0.6.1/lib/moneta/file'
require 'digest/md5'
require 'ostruct'
require 'pathname'

class Moneta::File
  include Enumerable
  def each &blk
    Dir.glob(::File.join(@directory, '*')).each do |path|
      path = Pathname.new path
      if blk.arity == 2
        blk.call path.basename.to_s, self[path.basename]
      else
        blk.call self[path.basename]
      end
    end
  end
end

class TodoList

  def help; Todo.help; end
  def self.help
    puts "you didn't enter a command. possible commands:
  new: create a new todo
  list: list your todos
  find: find a todo."
  end
  
  def initialize command, *args
    case command
    when 'new'
      command = 'create_todo'
    end
    
    send command, *args
  # rescue ArgumentError => e
  #   case command
  #   when 'create_todo'
  #     require 'ruby-debug'; debugger
  #     puts "'new' takes one argument, the name of the todo."
  #   else
  #     raise e
  #   end
  rescue NoMethodError => e
    puts "Invalid command.\n\n\n-------- Message --------"
    raise e
  end
  
  def storage
    @storage ||= Moneta::File.new :path => 'data'
  end
  
  def create_todo name
    todo = Todo.create self, name
  end
  
  def list
    storage.each do |key,val|
      puts val.inspect
    end
  end
  
  def find query
    todos = storage.select do |todo|
      todo.is_a?(Todo) && todo.name.match(/^#{query}/)
    end
    raise VagueQueryError if todos.length > 1
    todos.first
  end
  
  class VagueQueryError < StandardError; end
  def show query
    requires_spefic_todo query
    puts @found_todo.name
  end
  
  def requires_spefic_todo query
    @found_todo = find(query)
  rescue VagueQueryError => e
    puts "Too vague of a query."
  end
  
  def finish query
    requires_spefic_todo query
    @found_todo.finished = true
    @found_todo.save
  end
end

class PersistentOpenStruct < OpenStruct
  class Table < Hash
    def initialize storage, struct
      @storage = storage
      @struct = struct
      super nil
    end

    def []= key,val
      res = super
      persist
      res
    end

    def persist
      @storage[@struct.key] = self
    end
  end
  
  def initialize storage, hash = nil
    @storage = storage
    @table = Table.new storage, self
    if hash
      for k,v in hash
        @table[k.to_sym] = v
        new_ostruct_member(k)
      end
    end
  end
end

class Todo < PersistentOpenStruct
  attr_accessor :list, :key
  
  def initialize list 
    @list = list
    super list.storage
  end
  
  def key
    Digest::MD5.hexdigest name
  end
  
  def self.create list, name
    todo = new list
    todo.name = name
  end
end

if ARGV[0]
  TodoList.new *ARGV
else
  TodoList.help
end
