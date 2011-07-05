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

    # updates a base value with a new value, returning
    # the (possibly new) base value updated.
    def update_field(base_value, value)
      # base value should be an array of hobs,
      # while value should be an array of hashes
      raise InvalidFieldMatchError, "#{path_name} must be an Array" unless value.is_a?(Array)
      raise SmallerArrayError, "#{path_name} must be an Array with not less than #{base_value.size} items" if value.size < base_value.size
      to_be_removed = []
      (0...base_value.size).each do |idx|
        # TODO: manage deleted items
        if value[idx]['deleted']
          # puts "remove #{idx}th element: #{base_value[idx].inspect}"
          to_be_removed << idx
        else
          base_value[idx].update(value[idx])
        end
      end
      (base_value.size...value.size).each do |idx|
        unless value[idx]['deleted']
          hob = Hob.new(self)
          hob.update(value[idx])
          # puts "add #{base_value.size}th element: #{hob.inspect}"
          base_value << hob
        end
      end
      unless to_be_removed.empty?
        to_be_removed.reverse.each do |idx|
          base_value.delete_at(idx)
        end
      end
      base_value
    end

  end
end
