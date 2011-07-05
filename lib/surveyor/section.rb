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

  end
end
