# Section
# Container that although it has a list of elements,
# they really belong to the section's container (when instanciated)
# A section only generates a html wrapper for its elements,
# but references them to its container.
module Surveyor
  class Section < Container
    class NoBaseValueError < ::StandardError; end

    def base_value
      raise NoBaseValueError, 'a Section has no base value'
    end

  end
end
