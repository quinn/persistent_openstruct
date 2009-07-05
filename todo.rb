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

module TodoListMenu
  def menu choice = false
    puts " options:\n 1. find a todo
 2. make a new one
 3. list all the todos
 4. exit"
    choice ||= gets.chomp.to_i
    case choice
    when 1
    when 2      
      puts "whats it gonna be called??"
      create_todo gets
    when 3
      
    when 4
      exit
    else
      puts "invalid choice."
      menu
    end
  end
end

class TodoList
  include TodoListMenu
  
  def help; TodoList.help; end
  def self.help
    puts "possible commands:
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
    raise todo.inspect
  end
  
  def list
    @ref = []
    todos.each do |todo|
      puts todo.name
    end
  end
  
  def todos
    @todos ||= storage.select do |todo|
      todo.type_is?(Todo)
    end
  end
  
  def find query
    todos = todos.select do |todo|
      todo.name.match(/^#{query}/)
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
      persist unless key == :type
      res
    end

    def persist
      @storage[@struct.key] = self
    end
  end
  
  def initialize storage, hash = nil
    @storage = storage
    @table = Table.new storage, self
    self.type = self.class
    if hash
      for k,v in hash
        @table[k.to_sym] = v
        new_ostruct_member(k)
      end
    end
  end
  
  def type_is? type
    self.type == type
  end
end

class Todo < PersistentOpenStruct
  attr_accessor :list, :key
  
  def initialize list 
    @list = list
    super list.storage
  end
  
  def key
    @key ||= Digest::MD5.hexdigest(name)
  end
  
  def self.create list, name
    todo = new list
    todo.name = name
    todo
  end
end

if ARGV[0]
  TodoList.new *ARGV
else
  TodoList.new 'menu'
end
