module Surveyor
  class Element
    attr_reader :name, :parent, :options

    def initialize(parent_element, name, options)
      @parent = parent_element
      @name = name
      @options = options
    end

  end
end
