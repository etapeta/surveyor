module Surveyor
  class Hob

    def initialize(container, hhash = nil)
      raise ValidSurveyError, 'must pass a not-null container' unless container
      @container = container
      setup_interface_from(@container)
      update(hhash) if hhash
    end

    def update(hash)
      hash.each do |k,v|
        case v
        when Hash
          self[k].update(v)
        when Array
          hob_array = self[k]
          result_array = v.collecy do |item|
            # item should be a hash
            
            
            
            
            
            
            
            self[k].update(v)
        else
        end
      end
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
