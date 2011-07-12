module Surveyor
  #
  # A DomNamer holds naming information for a generic element.
  # When rendering a survey, as an element tree, the naming information
  # for any element is updated based on the elements currently being
  # visited.
  #
  # A DomNamer is also used in other situations different from rendering.
  #
  class DomNamer
    attr_reader :name, :id
    # Attributes of the main input element.
    # id   - id of the (main) input element.
    #        Note that the <label> tag of the element frame references it.
    # name - name of the (main) input element

    # Create the initiali dom namer for a traversion of the element tree.
    #
    # element - element the dom contain naming information for.
    #
    # Return a DomNamer
    def self.start(element)
      new(element.name, element.options[:id] || element.name)
    end

    # Initialize the dom namer
    #
    # name - name for the associated element
    # id   - id for the associated element
    def initialize(name, id)
      @name = name
      @id = id
    end

    # Instances a new dom namer that corresponds to a new tree level
    # for an element that is contained in the element currently
    # associated to the namer.
    #
    # element - inner element that the new dom namer must name
    #
    # Return a DomNamer
    def plus(elem)
      self.class.new("#{@name}[#{elem.name}]", "#{@id}:#{elem.options[:id] || elem.name}")
    end

    # Alias for :plus
    #
    # Return a DomNamer.
    def +(elem)
      plus(elem)
    end

    # Instances a new dom namer for an indexed instance of the
    # current object, which is an Array, associated to a multiplier.
    #
    # index - index of the element instance
    #
    # Return a DomNamer.
    def mult(index)
      self.class.new("#{@name}[]", "#{@id}:#{index}")
    end

    # Alias for :mult
    #
    # Return a DomNamer.
    def *(index)
      mult(index)
    end

  end
end
