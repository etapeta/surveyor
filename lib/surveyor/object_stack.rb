module Surveyor
  #
  # Object that represent a status in the bidimensional
  # navigation of a survey instance tree.
  #
  class ObjectStack
    attr_reader :element, :object, :parent, :dom_namer

    # Initialize a ObjectStack
    #
    # element   - element currently being navigated
    # object    - data corresponding to the element being navigated
    #             if element is a multiplier, object can either be:
    #             - an array of hobs
    #             - a hob
    # parent    - objectstack that generated this instance
    # dom_namer - naming information for current navigation
    #
    # Return nothing.
    def initialize(element, object, parent = nil, dom_namer = nil)
      @element = element
      @object = object
      @parent = parent
      @dom_namer = dom_namer || DomNamer.start(element)
    end

    # Hob that contains all survey data.
    # It contains possible validation errors.
    #
    # Return a Hob
    def root_object
      parent ? parent.root_object : object
    end

    # Object that holds data for the current element.
    # Generally, the object that holds data has a tree position
    # corresponding to the one of the element.
    # Two special cases:
    # 1. A Section instance holds no data
    # 2. A Multiplier has two instances, corresponding to two
    #    objectstacks: one for the array, and one for the array item.
    #
    # Return a Object.
    def owner_object
      object.is_a?(Array) ? parent.owner_object :
        object.container.identifiable? ? object : parent.owner_object
    end

    # A new objectstack that corresponds to an inner element of
    # the current element.
    #
    # element - element to create the objectstack for.
    #           It is a direct children of current element.
    #
    # Return a ObjectStack
    def +(element)
      # unless owner_object.respond_to?(element.name)
      #   raise "Not compatible:\n\tElement: #{element.inspect}\n\tObject: #{object.inspect}\n\tOwner: #{owner_object.inspect}\n\tself: #{self.inspect}\n\tparent: #{parent.inspect}"
      # end
      ObjectStack.new(element, 
        element.identifiable? ? owner_object.send(element.name) : object, 
        self,
        element.identifiable? ? dom_namer + element : dom_namer)
    end

    # A new objectstack that corresponds to an instance of
    # the current element, which is an Array.
    # This instance and the result instance will then be
    # associated to the same multiplier, respectively as
    # the whole array and a single array item.
    #
    # obj - Hob which represent an item of current element, 
    #       which is an Array[Hob]
    # idx - index that represents obj's position in current element.
    #
    # Return a ObjectStack
    def mult(obj, idx)
      unless element.type == 'multiplier'
        raise CannotMultiplyError, "Only multiplier objectstacks can be multiplied [not #{self.inspect}]"
      end
      ObjectStack.new(self.element, obj, self, dom_namer * idx)
    end

    # id which identifies the current position.
    # It is generally used in HTML rendering, to identify the widget
    # that the current element instance is rendered into.
    #
    # Return a String
    def dom_id
      dom_namer.id
    end

    # name which identify the position within the survey hash data.
    # It is used in HTML rendering, to name the widget.
    #
    # Return a String.
    def dom_name
      dom_namer.name
    end

    # Check if there is an error in the survey data at current position.
    #
    # Return true if there is any error, false otherwise.
    def error?
      root_object.error_for?(dom_namer)
    end

    # Execute a task in current survey data tree position.
    # survey data tree is traversed deep first.
    #
    # Return nothing.
    def traverse_deep_first(&blk)
      blk ||= lambda {|os| puts "#{os.dom_id}:#{os.object.inspect}" }
      blk.call self
      case element
      when Multiplier
        object.each_with_index do |obj, idx|
          obj_stack = mult(obj, idx)
          element.accepted_elements.each do |elem|
            (obj_stack + elem).traverse_deep_first(&blk)
          end
        end
      when Container
        # any other container
        element.accepted_elements.each do |elem|
          (self + elem).traverse_deep_first(&blk)
        end
      else
        # nothing
      end
    end
  end
end
