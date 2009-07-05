require 'rubygems'
require 'moneta-0.6.1/lib/moneta'
require 'moneta-0.6.1/lib/moneta/file'
require 'digest/md5'
require 'ostruct'
require 'pathname'
require 'uuid'

class Moneta::File
  include Enumerable
  def each &blk
    Dir.glob(::File.join(@directory, '*')).each do |path|
      path = Pathname.new path
      if blk.arity == 2
        blk.call path.basename.to_s, self[path.basename]
      else
        val = self[path.basename]
        val.key = path.basename.to_s if val.respond_to? :key
        blk.call self[path.basename]
      end
    end
  end
end

module TodoListMenu
  def menu choice = false
    puts "options:\n 1. find a todo
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
      puts "active todos:"
      list_active
    when 4
      return
    else
      puts "invalid choice."
    end
    menu
  end
  
  def list_active
    id = 1
    ref = {}
    todos.each do |todo|
      puts " #{id}. #{todo.name}"
      ref[id] = todo
      id += 1
    end
    puts " #{id}. (cancel)"
    choice ||= gets.chomp.to_i
    return if choice == id
    todo = ref[choice]
    if todo
      work_on_a_todo todo
    else
      puts "invalid entry"
    end
    list_active
  end
  
  def work_on_a_todo todo
    puts "What do you want to do with it?
 1. mark it as finished
 2. delete it forever"
    choice ||= gets.chomp.to_i
    case choice
    when 1
      todo.finished = true
      return
    when 2
      raise todo.key.inspect
      storage.delete(todo.key)
      return
    else
      puts "invalid entry."
    end
    work_on_a_todo todo
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
    ARGV.clear
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
    @ref = []
    todos.each do |todo|
      puts todo.name
    end
  end
  
  def todos
    @todos = storage.select do |item|
      item.is_a?(Todo)
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

class Todo < PersistentOpenStruct
  attr_accessor :list
  
  def initialize list, key = nil
    @list = list
    super list.storage, key
  end
  
  def key
    @key ||= UUID.generate
  end
  
  def self.create list, name
    todo = new list
    todo.name = name
    todo.save
  end
end

if ARGV[0]
  TodoList.new *ARGV
else
  TodoList.new 'menu'
end
