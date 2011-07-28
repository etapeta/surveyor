module Surveyor
  #
  # A Hob is a Hash with the possibility to reference its elements
  # through methods that correspond to the element names.
  #
  # Used in surveys, hobs have keys that are simple strings which match /^\w+$/
  # and values that are simple objects (strings, numbers, booleans), other hobs
  # or arrays of hobs.
  #
  # A hob always references the container it is containing values for.
  #
  class Hob
    attr_reader :container

    # Initialize a new hob.
    #
    # container - container element that defines the hob structure
    # hhash     - values for this hob
    #
    # Return nothing
    def initialize(container, hhash = nil)
      raise ValidSurveyError, 'must pass a not-null container' unless container
      @container = container
      setup_interface_from(@container)
      update(hhash) if hhash
    end

    # Update hob with new values.
    # Clears the hob's error status.
    #
    # hash - hash of new values. It can partially cover the whole hob.
    #
    # Return nothing
    def update(hash)
      errors.clear
      hash.each do |field,value|
        element = @container.accepted_element_at(field)
        raise UnknownFieldError, "#{@container.path_name}.#{field} does not exist" unless element
        self[field] = element.update_field(self[field], value)
      end
    end

    # Generate a hash of data for the hob
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

    # Content of a hob's field.
    #
    # field_name - name of the field
    #
    # Return a Object (String, Fixnum, boolean, Date, Hob, Array)
    def [](field_name)
      send(field_name)
    end

    # Set the content of a hob's field
    #
    # field_name - name of the field
    # value      - new content for the field
    #
    # Return nothing.
    def []=(field_name, value)
      send("#{field_name}=", value)
    end

    #
    # ActiveModel integration
    #

    include ActiveModel::Conversion
    extend ActiveModel::Naming
    extend ActiveModel::Translation
    include ActiveModel::Validations

    # Inherited from ActiveModel.
    # A Hob is not persisted.
    def persisted?
      false
    end

    validate :validate

    # Validation method.
    # Every content not accepted creates one or more errors.
    # The validation rules are stored in the survey.
    #
    # Return nothing.
    def validate
      return unless container.is_a?(Survey)
      ObjectStack.new(container, self).traverse_deep_first do |os|
        os.element.validate_value(os.object, os.local_id, errors)
      end
    end

    # Errors object that holds all information
    # about attribute error messages.
    #
    # Return a HobErrors.
    def errors
      @errors ||= HobErrors.new(self)
    end

    # Redefinition of ActiveModel's Errors
    class HobErrors < ::ActiveModel::Errors

      # All the full error messages for the hob.
      #
      # NOTE: Since all error message lose their association with the
      # survey that generated them, the attribute names cannot be
      # made exactly equal, because we cannot access element's
      # options[:label]
      #
      # Return an Array of String
      def full_messages
        full_messages = []

        each do |attribute, messages|
          messages = Array.wrap(messages)
          next if messages.empty?

          if attribute == :base
            messages.each {|m| full_messages << Element.i18n(m, m) }
          else
            # attribute is in :id format \w+(\.(\w+|\d+))*
            # es:
            #   player.2.matches.4.opponent.name
            # It should be humanized and translated into
            #   Player #2 > Match #4 > Opponent > Name

            separator = I18n.translate(:"survey.path_separator", :default => ' > ')
            # start changing indexes
            instance_path = attribute.to_s.split('.')
            attribute_path_name = instance_path.collect {|n|
              if n =~ /^\d+$/
                " ##{1 + n.to_i}"
              else
                attr_name = Element.i18n(:"survey.attributes.#{n}", n.humanize)
                "#{separator}#{attr_name}"
              end
            }.join('')[separator.size..-1]
            options = { :default => "%{attribute} %{message}", :attribute => attribute_path_name }
            messages.each do |m|
              msg = Element.i18n(m, m)
              full_messages << I18n.t(:"survey.error_format", options.merge(:message => msg))
            end
          end
        end

        full_messages
      end

      protected

    end

    # Find if there are errors corresponding to the position
    # given by a dom namer.
    #
    # dom_namer - DomNamer which holds a logical position
    #
    # Return true if errors exist for that dom namer, 
    # false otherwise.
    def error_for?(dom_namer)
      k = dom_namer.id.split(':')[1..-1].join('.')
      errors[k].any?
    end

    # Adds an error corresponding to the position given
    # by a dom namer.
    #
    # dom_namer - DomNamer which holds a logical position
    # error_symbol - symbol of an error. Errors can be found
    #                in I18n repository under the key survey.errors
    #
    # Return nothing.
    def mark_error(dom_namer, error_symbol)
      k = dom_namer.id.split(':')[1..-1].join('.')
      errors[k] << "survey.errors.#{error_symbol}"
    end

    # A human-readable representation of obj.
    #
    # Return a String
    def inspect
      self.class.name + "<#{container.type}>" + "{" + container.accepted_elements.collect {|e|
        e.name + ":" + (e.is_a?(Container) ? "...": self.send(e.name).inspect)
      }.join(',') + "}"
    end

    private

    # Eigenclass for the hob
    def eigenclass
      class << self
        self
      end
    end

    # Augments the hob interface by creating variables
    # and corresponding methods to access them
    # based on structure of the given element.
    #
    # container - the container whose element should be part of the hob interface
    #
    # Return nothing.
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
