module Surveyor
  class Hob
    attr_reader :container

    def initialize(container, hhash = nil)
      raise ValidSurveyError, 'must pass a not-null container' unless container
      @container = container
      setup_interface_from(@container)
      update(hhash) if hhash
    end

    def update(hash)
      errors.clear
      hash.each do |field,value|
        element = @container.accepted_element_at(field)
        raise UnknownFieldError, "#{@container.path_name}.#{field} does not exist" unless element
        self[field] = element.update_field(self[field], value)
      end
    end

    # generate a hash of data for the hob
    # if the container is a Multiplier, the hob represents one of its factors.
    # Note that generally the container of a hob cannot be a multiplier.
    # But in special cases, a hob should represent a multiplier's factor.
    def to_h
      if @container.is_a?(Multiplier)
        @container.simple_out([self]).first
      else
        @container.simple_out(self)
      end
    end

    def [](field_name)
      send(field_name)
    end

    def []=(field_name, value)
      send("#{field_name}=", value)
    end

    # ActiveModel integration

    include ActiveModel::Conversion
    extend ActiveModel::Naming
    extend ActiveModel::Translation
    include ActiveModel::Validations

    def persisted?
      false
    end

    private

    def eigenclass
      class << self
        self
      end
    end

    def setup_interface_from(container)
      container.elements.each do |elem|
        if elem.identifiable?
          eigenclass.send :define_method, elem.name, lambda { instance_variable_get("@#{elem.name}") }
          eigenclass.send :define_method, "#{elem.name}=", lambda {|value| instance_variable_set("@#{elem.name}", value) }
          instance_variable_set("@#{elem.name}", elem.default_value)
          if Surveyor::Sequence === elem
            send(elem.name).send(:setup_interface_from, elem)
          end
        else
          # section elements belongs to section's container, not to section
          setup_interface_from(elem)
        end
      end
    end

  end
end
