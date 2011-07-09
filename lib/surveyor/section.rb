# Section
# Container that although it has a list of elements,
# they really belong to the section's container (when instanciated)
# A section only generates a html wrapper for its elements,
# but references them to its container.
module Surveyor
  class Section < Container
    class HtmlRenderer < Surveyor::Container::HtmlRenderer
      def render(output, object, dom_namer, options)
        emit_tag(output, 'div', :class => element.type) do |output|
          emit_tag(output, 'h2', element.label) unless element.options[:no_label]
          element.elements.each do |elem|
            elem.renderer.render(output, object.send(elem.name), dom_namer + elem, elem.options)
          end
        end
      end
    end

    def default_value
      raise NoBaseValueError, 'a Section has no default value'
    end

    # updates current value with a new value, returning
    # the current value updated.
    def update_field(current_value, new_partial_value)
      raise NoBaseValueError, 'a Section has no value to update'
    end

    def renderer
      HtmlRenderer.new(self)
    end

    # an element is identifiable if it needs an id in HTML rendering
    def identifiable?
      false
    end

  end
end
