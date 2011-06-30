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

  end
end
