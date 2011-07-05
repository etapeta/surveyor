module Surveyor
  class Hob

    def initialize(container, hhash = nil)
      raise ValidSurveyError, 'must pass a not-null container' unless container
      @container = container
      setup_interface_from(@container)
      update(hhash) if hhash
    end

    def update(hash)
      hash.each do |field,value|
        element = @container.accepted_element_at(field)
        raise UnknownFieldError, "#{@container.path_name}.#{field} does not exist" unless element
        self[field] = element.update_field(self[field], value)
      end
    end

    def to_h
      @container.simple_out(self)
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
        case elem
        when Surveyor::Section
          # section elements belongs to section's container, not to section
          setup_interface_from(elem)
        else # element or container (except multipliers)
          eigenclass.send :define_method, elem.name, lambda { instance_variable_get("@#{elem.name}") }
          eigenclass.send :define_method, "#{elem.name}=", lambda {|value| instance_variable_set("@#{elem.name}", value) }
          instance_variable_set("@#{elem.name}", elem.base_value)
          if Surveyor::Sequence === elem
            send(elem.name).send(:setup_interface_from, elem)
          end
        end
      end
    end

  end
end
