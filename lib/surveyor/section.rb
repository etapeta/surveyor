# Section
# Container that although it has a list of elements,
# they really belong to the section's container (when instanciated)
# A section only generates a html wrapper for its elements,
# but references them to its container.
module Surveyor
  class Section < Container
    class HtmlCoder < Surveyor::Container::HtmlCoder
      def emit(output, object, dom_namer, options)
        emit_tag(output, 'div', :class => element.type) do |output|
          emit_tag(output, 'h2', element.label) unless element.options[:no_label]
          element.elements.each do |elem|
            elem.html_coder.emit(output, object.send(elem.name), dom_namer + elem, elem.options)
          end
        end
      end
    end

    def base_value
      raise NoBaseValueError, 'a Section has no base value'
    end

    # updates a base value with a new value, returning
    # the (possibly new) base value updated.
    def update_field(base_value, value)
      raise NoBaseValueError, 'a Section has no base value to update'
    end

    def html_coder
      HtmlCoder.new(self)
    end

    # an element is identifiable if it needs an id in HTML rendering
    def identifiable?
      false
    end

  end
end
