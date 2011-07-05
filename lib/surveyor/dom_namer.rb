class DomNamer
  attr_reader :name, :id

  def initialize(name, id)
    @name = name
    @id = id
  end

  def plus(elem)
    self.class.new("#{@name}[#{elem.name}]", "#{@id}:#{elem.options[:id] || elem.name}")
  end

  def +(elem)
    plus(elem)
  end

  def mult(index)
    self.class.new("#{@name}[]", "#{@id}:#{index}")
  end

  def *(index)
    mult(index)
  end

end
