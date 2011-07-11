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

    validate :validate

    def validate
      return unless container.is_a?(Survey)
      container.validate_value(self, DomNamer.start(container), self)
    end

    # Returns the Errors object that holds all information about attribute error messages.
    def errors
      @errors ||= HobErrors.new(self)
    end

    class HobErrors < ::ActiveModel::Errors

      # Returns all the full error messages in an array.
      def full_messages
        full_messages = []

        each do |attribute, messages|
          messages = Array.wrap(messages)
          next if messages.empty?

          if attribute == :base
            messages.each {|m| full_messages << translated_message(m) }
          else
            # attribute is in :id format \w+(\.(\w+|\d+))*
            # es:
            #   player.2.matches.4.opponent.name
            # It should be humanized and translated into
            #   Player #2 > Match #4 > Opponent > Name

            separator = I18n.translate(:"survey.path_separator", :default => ' > ')
            # start changing indexes
            attribute_path_name = attribute.to_s.split('.').collect {|n|
              if n =~ /^\d+$/
                " ##{1 + n.to_i}"
              else
                attr_name = I18n.translate(:"survey.attributes.#{n}", :default => n.humanize)
                "#{separator}#{attr_name}"
              end
            }.join('')[separator.size..-1]
            options = { :default => "%{attribute} %{message}", :attribute => attribute_path_name }
            messages.each do |m|
              msg = I18n.t(m, :default => m)
              full_messages << I18n.t(:"survey.error_format", options.merge(:message => msg))
            end
          end
        end

        full_messages
      end

      protected

      def translated_message(msg)
        (msg =~ /^[\w\.]+$/) ? I18n.t(msg) : msg
      end

    end

    def error_for?(dom_namer)
      k = dom_namer.id.split(':')[1..-1].join('.')
      errors[k].any?
    end

    def mark_error(dom_namer, error_symbol)
      k = dom_namer.id.split(':')[1..-1].join('.')
      errors[k] << "survey.errors.#{error_symbol}"
    end

    def inspect
      self.class.name + "<#{container.type}>" + "{" + container.accepted_elements.collect {|e|
        e.name + ":" + (e.is_a?(Container) ? "...": self.send(e.name).inspect)
      }.join(',') + "}"
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
