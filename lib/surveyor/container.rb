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

    class HtmlCoder < Surveyor::Element::HtmlCoder

      def emit(output, object, dom_namer, options)
        html_attrs = element.identifiable? ? { :id => dom_namer.id } : {}
        output.safe_concat(tag('div', html_attrs.merge({:id => dom_namer.id}), true))
        output.safe_concat "<h2>#{element.label}</h2>"  # TODO: if label required
        element.elements.each do |elem|
          if elem.identifiable?
            elem.html_coder.emit(output, object.send(elem.name), dom_namer + elem, elem.options)
          else
            elem.html_coder.emit(output, object, dom_namer, elem.options)
          end
        end
        output.safe_concat("</div>")
      end

    end

    # create a html expert that represents object as an element in HTML.
    def html_coder
      HtmlCoder.new(self)
    end

  end
end
