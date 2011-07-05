module Surveyor
  class Container < Element
    attr_reader :elements

    def initialize(parent_element, name, options)
      super(parent_element, name, options)
      @elements = []
    end

    # The default value that this element has when the survey
    # is instanciated (empty)
    # Since this element resembles an ordered hash, with
    # keys being element names, it has a hob as base value.
    def base_value
      Hob.new(self)
    end

    # updates a base value with a new value, returning
    # the (possibly new) base value updated.
    def update_field(b_value, value)
      raise InvalidFieldMatchError, "#{path_name} must be a Hash" unless value.is_a?(Hash)
      # b_value must be a Hob, and it can be updated with a hash
      b_value.update(value)
      b_value
    end
  end
end
