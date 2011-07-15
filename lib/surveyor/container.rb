module Surveyor
  #
  # Abstract element that contains other elements.
  #
  class Container < Element
    #
    # Generic renderer for a Container
    #
    class HtmlRenderer < Surveyor::Element::HtmlRenderer

      # Render a HTML representation of a Container
      #
      # output       - output buffer
      # object_stack - stack of the element instances being rendered
      #
      # Return nothing
      def render(output, object_stack)
        return if element.options[:killed]
        html_attrs = element.identifiable? ? { :id => object_stack.dom_id } : {}
        emit_tag(output, 'div', html_attrs.merge({:class => "surv-container #{element.type}"})) do |output|
          emit_tag(output, 'h2', element.label) unless element.options[:no_label]
          element.elements.each do |elem|
            if elem.identifiable?
              elem.renderer.render(output, object_stack + elem)
            else
              elem.renderer.render(output, object_stack)
            end
          end
          if element.options[:inner] && element.options[:inner][:label_remove]
            # this is a multiplier template: render the remover link
            emit_tag output, 'div', :class => 'mult_remover' do
              output << link_to_function(element.options[:inner][:label_remove], 'removeFactor(this)')
            end
          end
        end
      end

      # Render a HTML template of the element, if necessary.
      # A template is a HTML partial which can be used by
      # an element instance to update itself based on certain
      # element events.
      # Currently, only multiplier need to render templates.
      # All template are contained within a hidden div.
      #
      # output    - rendering buffer
      # dom_namer - naming information for the template
      #
      # Return nothing.
      def render_templates(output, dom_namer)
        # do nothing, but continue searching other templates
        element.elements.each do |elem|
          if elem.identifiable?
            elem.renderer.render_templates output, dom_namer + elem
          else
            elem.renderer.render_templates output, dom_namer
          end
        end
      end

    end

    # Array representing the list of elements contained
    attr_reader :elements

    # Initialize the container.
    #
    # parent_element - element which contains this container, or
    #                  null if none exists.
    #                  Surveys always have null parent_element.
    # name           - path-relative identifier for the element
    # options        - element options.
    #
    # Return nothing
    def initialize(parent_element, name, options)
      super(parent_element, name, options)
      @elements = []
    end

    # Clone the current element in a parallel tree
    #
    # parent_element - container for the clone tree
    #
    # Return the new element for the clone tree.
    def clone(parent_element)
      result = self.class.new(parent_element, name, options.clone)
      elements.each do |elem|
        result.elements << elem.clone(result)
      end
      result
    end

    # Default value that this element has when the survey
    # is instanciated (empty).
    # Since this element resembles an ordered hash, with
    # keys being element names, it has a hob as base value.
    #
    # Return a Object
    def default_value
      Hob.new(self)
    end

    # Update current value with a new value, returning
    # the current value updated.
    # For a general container, current_value is a Hob and new_partial_value
    # is a Hash.
    #
    # current_value     - current value for the element
    # new_partial_value - partial value having new information for the current value
    #
    # Return the new current value updated
    def update_field(current_value, new_partial_value)
      raise InvalidFieldMatchError, "#{path_name} must be a Hash" unless new_partial_value.is_a?(Hash)
      # b_value must be a Hob, and it can be updated with a hash
      current_value.update(new_partial_value)
      current_value
    end

    # Validates current value on element's rules.
    # Sets root_hob.errors on failed validations with dom_namer's id.
    #
    # current_value - current value for the element
    # dom_namer     - naming information for the element
    # root_hob      - Hob that corresponds to the Survey, and holds all errors
    #                 for the element tree
    #
    # Return nothing
    def validate_value(current_value, dom_namer, root_hob)
      # reflects validations on elements
      accepted_elements.each do |elem|
        elem.validate_value current_value.send(elem.name), dom_namer + elem, root_hob
      end
    end

    # Generate a simple representation of the element's value
    # i.e. hash, array or simple value.
    # For a general container, the result is a Hash.
    #
    # b_value - object to extract data from
    #
    # Return an Object (generally a Hash, but it could 
    # be an Array if container is a multiplier)
    def simple_out(b_value)
      # a container generates an hash from an hob
      accepted_elements.inject(Hash[]) do |hash,elem|
        if b_value.respond_to?(elem.name)
          hash[elem.name] = elem.simple_out(b_value.send(elem.name))
        end
        hash
      end
    end

    # All directly accessible elements of the container.
    # It corresponds to the direct elements with sections
    # recursively replaced with their contained elements.
    #
    # recurse - flag that is true if this element is the
    #           first element involved in the recursive search.
    #
    # Return an Array
    def accepted_elements(recurse = false)
      elements.collect {|elem| elem.identifiable? ? elem: elem.accepted_elements(true) }.flatten
    end

    # Finds the element that matches the name.
    #
    # field_name - name identificative of the field locally to its container.
    #
    # Return a Element or nil.
    def accepted_element_at(field_name)
      elements.each do |elem|
        return elem if elem.name == field_name
        unless elem.identifiable?
          # section elements are accessible directly from its container
          result = elem.accepted_element_at(field_name)
          return result if result
        end
      end
      nil
    end

    # A html expert that can render a HTML representation for the element.
    #
    # Return a Object that respond to :render(output, object_stack).
    def renderer
      HtmlRenderer.new(self)
    end

    # Find an inner element by path name.
    #
    # path - path name of the searched element. Es: surv.tennis.tournaments
    #
    # Return a Element or nil.
    def find(path)
      if path.is_a?(String)
        find path.split('.')
      elsif path.empty?
        return self
      else
        elem = elements.detect {|elem| elem.name == path[0]}
        elem.nil? ? nil : path.size == 1 ? elem : elem.find(path[1..-1])
      end
    end

    # A human-readable representation of obj.
    #
    # Return a String
    def inspect
      elems = elements.collect {|elem| "#{elem.name}:##{elem.type}"}
      "#<#{self.class.name}:##{self.path_name} {elements:[#{elems.join(',')}]}>"
    end

  end
end
