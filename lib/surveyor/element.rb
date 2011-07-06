module Surveyor
  class Element
    class HtmlCoder
      include ActionView::Helpers::FormTagHelper
      attr_reader :element

      def initialize(elem)
        @element = elem
      end

      # Emits the HTML representation for an element
      # Standard frame:
      #   <p class='surv-block'>
      #     <label for="fieldid"/>
      #     <div class='surv-item'>
      #       ...  # es: <input id="fieldid" name="fieldname"/>
      #     </div>
      #   </p>
      def emit(output, object, dom_namer, options)
        # create the frame and the label, and let every element
        # to emit its own widget
        output.safe_concat tag('div', { :class => 'surv-block' }, true)
        # label
        output.safe_concat content_tag('label', element.label, { :for => dom_namer.id })
        # encapsulate the widget in a div
        output.safe_concat tag('div', { :class => element.type }, true)
        emit_widget output, object, dom_namer, options
        output.safe_concat "</div>"
        output.safe_concat "</div>"
      end

      protected

      def emit_widget(output, object, dom_namer, options)
        raise ImplementedBySubclassError, 'must be implemented by subclass'
      end

      def protect_against_forgery?
        false
      end
    end

    attr_reader :name, :parent, :options

    def initialize(parent_element, name, options)
      @parent = parent_element
      @name = name
      @options = options
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
    def base_value
      # generally, elements contain string (except containers)
      ''
    end

    # generates a simple representation of the element's value
    # i.e. hash, array or simple value
    def simple_out(b_value)
      # generally, elements contain string (except containers)
      b_value
    end

    # updates a base value with a new value, returning
    # the (possibly new) base value updated.
    def update_field(base_value, value)
      # generally, elements contain string (except containers)
      # so the new base value is the newly proposed value
      raise InvalidFieldMatchError, "#{path_name} must be a String" unless value.is_a?(String)
      value
    end

  end
end
