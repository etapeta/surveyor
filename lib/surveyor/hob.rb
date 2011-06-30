module Surveyor
  class Hob
    class ValidSurveyError < ::StandardError; end

    def initialize(container, hhash = {})
      raise ValidSurveyError, 'must pass a not-null container' unless container
      @container = container
      setup_interface_from(@container)
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
        end
      end
    end

  end
end
