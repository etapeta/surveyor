module Surveyor
  class Container < Element
    class HtmlRenderer < Surveyor::Element::HtmlRenderer

      def render(output, object, dom_namer, options)
        html_attrs = element.identifiable? ? { :id => dom_namer.id } : {}
        emit_tag(output, 'div', html_attrs.merge({:class => "surv-container #{element.type}"})) do |output|
          emit_tag(output, 'h2', element.label) unless element.options[:no_label]
          element.elements.each do |elem|
            if elem.identifiable?
              elem.renderer.render(output, object.send(elem.name), dom_namer + elem, elem.options)
            else
              elem.renderer.render(output, object, dom_namer, elem.options)
            end
          end
        end
      end

      def render_templates(output, dom_namer)
        element.elements.each do |elem|
          if elem.identifiable?
            elem.renderer.render_templates output, dom_namer + elem
          else
            elem.renderer.render_templates output, dom_namer
          end
        end
      end

    end

    attr_reader :elements

    def initialize(parent_element, name, options)
      super(parent_element, name, options)
      @elements = []
    end

    def clone(parent_element)
      result = self.class.new(parent_element, name, options)
      elements.each do |elem|
        result.elements << elem.clone(result)
      end
      result
    end

    # The default value that this element has when the survey
    # is instanciated (empty)
    # Since this element resembles an ordered hash, with
    # keys being element names, it has a hob as base value.
    def default_value
      Hob.new(self)
    end

    # updates current value with a new value, returning
    # the current value updated.
    def update_field(current_value, new_partial_value)
      raise InvalidFieldMatchError, "#{path_name} must be a Hash" unless new_partial_value.is_a?(Hash)
      # b_value must be a Hob, and it can be updated with a hash
      current_value.update(new_partial_value)
      current_value
    end

    # validates current value on element's rules.
    # Sets root_hob.errors on failed validations with dom_namer's id.
    def validate_value(current_value, dom_namer, root_hob)
      # reflects validations on elements
      accepted_elements.each do |elem|
        elem.validate_value current_value.send(elem.name), dom_namer + elem, root_hob
      end
    end

    # generates a simple representation of the element's value
    # i.e. hash, array or simple value
    def simple_out(b_value)
      # a container generates an hash from an hob
      accepted_elements.inject(Hash[]) do |hash,elem|
        if b_value.respond_to?(elem.name)
          hash[elem.name] = elem.simple_out(b_value.send(elem.name))
        end
        hash
      end
    end

    # all directly accessible elements of the container
    def accepted_elements
      elements.collect {|elem| elem.identifiable? ? elem: elem.accepted_elements }.flatten
    end

    # finds the element that matches the field
    def accepted_element_at(field)
      elements.each do |elem|
        return elem if elem.name == field
        unless elem.identifiable?
          # section elements are accessible directly from its container
          result = elem.accepted_element_at(field)
          return result if result
        end
      end
      nil
    end

    # create a html expert that represents object as an element in HTML.
    def renderer
      HtmlRenderer.new(self)
    end

    # finds an inner element by path
    def find(path)
      if path.is_a?(String)
        find path.split('.')
      else
        elem = elements.detect {|elem| elem.name == path[0]}
        elem.nil? ? nil : path.size == 1 ? elem : elem.find(path[1..-1])
      end
    end

  end
end
