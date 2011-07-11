module Surveyor
  class ObjectStack
    attr_reader :element, :object, :parent, :dom_namer

    # Note: if element is a multiplier, object can either be:
    # - an array of hobs
    # - a hob
    def initialize(element, object, parent = nil, dom_namer = nil)
      @element = element
      @object = object
      @parent = parent
      @dom_namer = dom_namer || DomNamer.start(element)
    end

    def root_object
      parent ? parent.root_object : object
    end

    def owner_object
      object.is_a?(Array) ? parent.owner_object :
        object.container.identifiable? ? object : parent.owner_object
    end

    def +(element)
      # unless owner_object.respond_to?(element.name)
      #   raise "Not compatible:\n\tElement: #{element.inspect}\n\tObject: #{object.inspect}\n\tOwner: #{owner_object.inspect}\n\tself: #{self.inspect}\n\tparent: #{parent.inspect}"
      # end
      ObjectStack.new(element, 
        element.identifiable? ? owner_object.send(element.name) : object, 
        self,
        element.identifiable? ? dom_namer + element : dom_namer)
    end

    def mult(obj, idx)
      unless element.type == 'multiplier'
        raise CannotMultiplyError, "Only multiplier objectstacks can be multiplied [not self.inspect]"
      end
      ObjectStack.new(self.element, obj, self, dom_namer * idx)
    end

    def dom_id
      dom_namer.id
    end

    def dom_name
      dom_namer.name
    end

    def error?
      root_object.error_for?(dom_namer)
    end

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
