class Todo < PersistentOpenStruct
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
