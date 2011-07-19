module Surveyor
  #
  # A Section is a container that although it has a list of elements,
  # they really belong to the section's container (when instanciated)
  # A section only generates a html wrapper for its elements,
  # but references them to its container.
  #
  # While other container have an id calculated from survey renderering
  # engine, sections are not identified.
  # They can, though, be given a custom id just in order to identify them
  # in DOM.
  #
  # Options for this element:
  # :id - custom id of the frame that contains the section elements
  #
  class Section < Container

    # Default value that this element has when the survey
    # is instanciated (empty).
    # But a section has no value, so this method
    # should never be called.
    #
    # Return a Object
    def default_value
      raise NoBaseValueError, 'a Section has no default value'
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
      return [] unless recurse
      elements.collect {|elem| elem.identifiable? ? elem: elem.accepted_elements(true) }.flatten
    end

    # Update current value with a new value, returning
    # the current value updated.
    # But a section owns no elements, so this method
    # should never be called.
    #
    # current_value     - current value for the element
    # new_partial_value - partial value having new information for the current value
    #
    # Return the new current value updated
    def update_field(current_value, new_partial_value)
      raise NoBaseValueError, 'a Section has no value to update'
    end

    # Validates current value on element's rules.
    # Sets root_hob.errors on failed validations with dom_namer's id.
    # But a section owns no elements, so this method
    # should never be called.
    #
    # current_value - current value for the element
    # dom_namer     - naming information for the element
    # root_hob      - Hob that corresponds to the Survey, and holds all errors
    #                 for the element tree
    #
    # Return nothing
    def validate_value(current_value, dom_namer, root_hob)
      raise NoBaseValueError, "a Section has no value to validate (#{dom_namer.id})"
    end

    # An element is identifiable if it owns its elements.
    # A section is (currently) the only element not identifiable.
    #
    # Return false.
    def identifiable?
      false
    end

  end
end
