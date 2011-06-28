module Surveyor
  class Container < Element
    attr_reader :elements

    def initialize(parent_element, name, options)
      super(parent_element, name, options)
      @elements = []
    end

  end
end
