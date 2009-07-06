# class Todo < PersistentOpenStruct
#   
#   def key
#     @key ||= UUID.generate
#   end
#   
#   def self.create list, name
#     todo = new list
#     todo.name = name
#     todo.save
#   end
# end
