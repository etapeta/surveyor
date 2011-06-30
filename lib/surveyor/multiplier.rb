module Surveyor
  class Multiplier < Container

    # The default value that this element has when the survey
    # is instanciated (empty).
    #
    # Since this element resembles an ordered list of hashes,
    # the base element is an empty list. At runtime, the list
    # will be filled with hobs (that will be initialized with 
    # the elements of this container).
    def base_value
      []
    end

  end
end
