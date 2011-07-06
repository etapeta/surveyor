# Section
# Container that although it has a list of elements,
# they really belong to the section's container (when instanciated)
# A section only generates a html wrapper for its elements,
# but references them to its container.
module Surveyor
  class Section < Container

    def base_value
      raise NoBaseValueError, 'a Section has no base value'
    end

    # updates a base value with a new value, returning 
    # the (possibly new) base value updated.
    def update_field(base_value, value)
      raise NoBaseValueError, 'a Section has no base value to update'
    end

    class HtmlCoder < Surveyor::Element::HtmlCoder

      def emit(output, object, dom_namer, options)
        output.safe_concat '<div class="section">'
        output.safe_concat "<h2>#{element.label}</h2>"
        element.elements.each do |elem|
          elem.html_coder.emit(output, object.send(elem.name), dom_namer + elem, elem.options)
        end
        output.safe_concat "</div>"
      end

    end

    def html_coder
      HtmlCoder.new(self)
    end

  end
end
