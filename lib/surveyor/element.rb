module Surveyor
  class Element
    attr_reader :name, :parent, :options

    def initialize(parent_element, name, options)
      @parent = parent_element
      @name = name
      @options = options
    end

    # Name of the element within the survey
    def path_name
      @parent ? "#{@parent.path_name}.#{name}" : name
    end

    # the survey is the root of all containers
    def survey
      parent ? parent.survey : self
    end

    # The default value that this element has when the survey
    # is instanciated (empty)
    def base_value
      # generally, elements contain string (except containers)
      ''
    end

  end
end
