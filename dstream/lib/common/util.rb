
class Util
  def obj_to_hash(obj)
    hash={}
    obj.instance_variables.each do |var|
      name=var[1,1000] #strip off @ from beginning
      hash[name]=obj.instance_variable_get(var)
    end
    return hash
  end

  def hash_to_obj(hash,obj_type)
    obj=obj_type.new
    hash.each do |pair|
      obj.send(pair[0]+"=",pair[1]) if obj.respond_to?(pair[0]+"=")
    end
    return obj
  end

end

class Bla
  attr_accessor :a,:b
end

#tmp=Bla.new
#tmp.a=4
#tmp.b="hello"

#hash=Util.new.obj_to_hash(tmp)
#puts hash.inspect

#tmp2=Util.new.hash_to_obj(hash,Bla)
#puts tmp2.inspect
