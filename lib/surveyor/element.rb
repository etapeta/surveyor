module Surveyor
  class Element
    class HtmlRenderer
      include ActionView::Helpers::FormTagHelper
      attr_reader :element

      def initialize(elem)
        @element = elem
      end

      # Renders the element instance in HTML code
      # Standard frame:
      #   <p class='surv-block'>
      #     <label for="fieldid"/>
      #     <div class='surv-item'>
      #       ...  # es: <input id="fieldid" name="fieldname"/>
      #     </div>
      #   </p>
      def render(output, object_stack, options)
        # create the frame and the label, and let every element
        # to render its own widget
        css = 'surv-block'
        css += ' error' if object_stack.error?
        emit_tag(output, 'div', :class => css) do |output|
          emit_tag(output, 'label', :for => object_stack.dom_id) do |output|
            output << element.label
            emit_tag(output, 'span', Element.required_label) if element.options[:required]
          end
          emit_tag(output, 'div', :class => element.type) do |output|
            render_widget output, object_stack.object, object_stack.dom_namer, options
          end
        end
      end

      def render_templates(output, dom_namer)
        # only multipliers really render templates
      end

      protected

      def render_widget(output, object, dom_namer, options)
        raise ImplementedBySubclassError, "must be implemented by subclass [#{element.class.name}]"
      end

      def emit_tag(output, tag_name, content_or_attributes = nil, attributes = nil, &block)
        if block
          raise TooMuchContentError, 'cannot have content and block' if attributes
          output.safe_concat tag(tag_name, content_or_attributes, true)
          block.call(output)
          output.safe_concat "</#{tag_name}>"
        elsif content_or_attributes.is_a?(Hash)
          # simple tag
          output.safe_concat tag(tag_name, content_or_attributes)
        else
          # tag with content
          output.safe_concat content_tag(tag_name, content_or_attributes, attributes || {})
        end
      end

      def protect_against_forgery?
        false
      end
    end

    attr_reader :name, :parent, :options

    def self.required_label
      I18n.t(:"survey.required", :default => '*')
    end

    def initialize(parent_element, name, options)
      @parent = parent_element
      @name = name
      @options = options
    end

    def clone(parent_element)
      self.class.new(parent_element, name, options)
    end

    # type of element.
    # Used in setting the CSS class for the element.
    # Es: multiplier, sequence, section, string, ...
    def type
      ty = self.class.name.split('::').last.downcase
      (ty =~ /element$/) ? ty[0...-7] : ty
    end

    # Name of the element within the survey
    def path_name
      @parent ? "#{@parent.path_name}.#{name}" : name
    end

    # the survey is the root of all containers
    def survey
      parent ? parent.survey : self
    end

    # text that introduces the field.
    # TODO: Based on I18n rules
    def label
      name
    end

    # The default value that this element has when the survey
    # is instanciated (empty)
    def default_value
      # generally, elements contain string (except containers)
      ''
    end

    # generates a simple representation of the element's value
    # i.e. hash, array or simple value
    def simple_out(b_value)
      # generally, elements contain string (except containers)
      b_value
    end

    # updates current value with a new value, returning
    # the current value updated.
    #
    # NOTE: Consider that the new value can be a partial value,
    # so it is not intended to replace the current value but only
    # to update it.
    # Besides, the new value is always a simple value (string, hash, array)
    # while the old value could be a higher structure (depending on the element).
    def update_field(current_value, new_partial_value)
      raise ImplementedBySubclassError, "must be implemented by subclass [#{element.class.name}]"
    end

    # validates current value on element's rules.
    # Sets root_hob.errors on failed validations with dom_namer's id.
    def validate_value(current_value, dom_namer, root_hob)
      raise ImplementedBySubclassError, "must be implemented by subclass [#{element.class.name}]"
    end

    # an element is identifiable if it needs an id in HTML rendering.
    # Generally, all elements are identifiable except sections.
    def identifiable?
      true
    end

    def inspect
      "#<#{self.class.name}:##{self.path_name}>"
    end

  end
end
