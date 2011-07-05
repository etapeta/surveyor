module Surveyor
  class Element
    class HtmlCoder
      include ActionView::Helpers::FormTagHelper

      protected

      def protect_against_forgery?
        false
      end
    end

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

    # generates a simple representation of the element's value
    # i.e. hash, array or simple value
    def simple_out(b_value)
      # generally, elements contain string (except containers)
      b_value
    end

    # updates a base value with a new value, returning
    # the (possibly new) base value updated.
    def update_field(base_value, value)
      # generally, elements contain string (except containers)
      # so the new base value is the newly proposed value
      raise InvalidFieldMatchError, "#{path_name} must be a String" unless value.is_a?(String)
      value
    end

    def emit_html(output, object, dom_namer, options)
    end

  end
end
