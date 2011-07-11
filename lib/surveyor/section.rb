# Section
# Container that although it has a list of elements,
# they really belong to the section's container (when instanciated)
# A section only generates a html wrapper for its elements,
# but references them to its container.
module Surveyor
  class Section < Container
    class HtmlRenderer < Surveyor::Container::HtmlRenderer
      def render(output, object_stack, options)
        emit_tag(output, 'div', :class => element.type) do |output|
          emit_tag(output, 'h2', element.label) unless element.options[:no_label]
          element.elements.each do |elem|
            elem.renderer.render(output, object_stack + elem, elem.options)
          end
        end
      end
    end

    def default_value
      raise NoBaseValueError, 'a Section has no default value'
    end

    # all directly accessible elements of the container
    # A section has no directly accessible element.
    def accepted_elements(recurse = false)
      return [] unless recurse
      elements.collect {|elem| elem.identifiable? ? elem: elem.accepted_elements(true) }.flatten
    end

    # updates current value with a new value, returning
    # the current value updated.
    def update_field(current_value, new_partial_value)
      raise NoBaseValueError, 'a Section has no value to update'
    end

    def validate_value(current_value, dom_namer, root_hob)
      raise NoBaseValueError, "a Section has no value to validate (#{dom_namer.id})"
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
