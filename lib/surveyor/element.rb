module Surveyor
  #
  # Abstract component of a Survey.
  #
  # When rendered, it is composed of a frame, which contains the label,
  # the tip and is generally common to all elements, and a widget,
  # which contains the input element and possible interactivity mechanisms.
  #
  # Options for all elements:
  # :id       - id for the widget. It influences possible inner elements' ids.
  # :class    - css class of the frame that contains the input widget
  # :readonly - if true, the element, and possibly any inner element, cannot be changed.
  # :label    - label of the element
  # :tip      - description of the element and possible help
  #
  class Element
    #
    # Abstract renderer for an Element.
    #
    class HtmlRenderer
      include ActionView::Helpers::FormTagHelper
      attr_reader :element

      # Initialize the renderer.
      #
      # element - element the renderer has to render.
      #
      # Return nothing.
      def initialize(elem)
        @element = elem
      end

      # Renders the HTML code for the element instance
      # Note that the standard frame for any element is:
      #   <p class='surv-block'>
      #     <label for="fieldid"/>
      #     <div class='surv-item'>
      #       ...  # es: <input id="fieldid" name="fieldname"/>
      #     </div>
      #   </p>
      # Override this method to have a different one.
      #
      # output - buffer that holds the rendering result
      # object_stack - ObjectStack which represents the stack of the pairs
      #                element/value currently being rendered and their
      #                associated information, such as the naming info.
      #
      # Return nothing.
      def render(output, object_stack)
        emit_standard_frame(output, object_stack) do |output|
          render_widget output, object_stack
        end
      end

      # Generate a standard frame for an element.
      # It can be customized, but probably that requires
      # a revision of the javascript code.
      def emit_standard_frame(output, object_stack, &blk)
        # create the frame and the label, and let every element
        # to render its own widget
        css = 'surv-block'
        css += ' error' if object_stack.error?
        css += " #{options[:class]}" if options[:class]
        emit_tag(output, 'div', :class => css) do |output|
          emit_tag(output, 'label', :for => object_stack.dom_id) do |output|
            output << element.label
            emit_tag(output, 'span', Element.required_label) if element.options[:required]
          end
          if options[:tip]
            emit_tag(output, 'div', t(options[:tip], :default => options[:tip]),
              :class => 'tip')
          end
          emit_tag(output, 'div', :class => element.type) do |output|
            blk.call(output)
          end
        end
      end

      # Render a HTML template of the element, if necessary.
      # A template is a HTML partial which can be used by
      # an element instance to update itself based on certain
      # element events.
      # Currently, only multiplier need to render templates.
      # All template are contained within a hidden div.
      #
      # output    - rendering buffer
      # dom_namer - naming information for the template
      #
      # Return nothing.
      def render_templates(output, dom_namer)
        # Does nothing. Only multipliers really render templates
      end

      protected

      # Render the HTML reresentation for inner part
      # of the frame that characterizes the string element.
      #
      # output - buffer in which the representation is put
      # object_stack - objectstack that represents the position
      #                within the survey instance tree
      #
      # Return nothing.
      def render_widget(output, object_stack)
        raise ImplementedBySubclassError, "must be implemented by subclass [#{element.class.name}]"
      end

      # Utility method that outputs a HTML tag.
      #
      # output                - buffer to write the HTML code into
      # tag_name              - name of the tag
      # content_or_attributes - String or Hash. 
      #                         If a block is given that defines the content, so
      #                         this is a Hash containing the tag's attributes.
      #                         Otherwise, it is a String representing the tag content.
      # attributes            - nil if a block is given.
      #                         Otherwise it is a Hash containing the tag's attributes.
      # block                 - proc containing the definition of the tag content.
      #                         The proc is passed the output buffer as argument.
      #
      # Return nothing.
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

      # Redefined.
      def protect_against_forgery?
        false
      end
    end

    attr_reader :name, :parent, :options

    # Label that is attached to an element label tag
    # to mark it as mandatory.
    #
    # Return a String.
    def self.required_label
      I18n.t(:"survey.required", :default => '*')
    end

    # Initialize the element.
    #
    # parent_element - container element that holds this element
    # name           - path-relative identifier for the element
    # options        - element options. General element options are:
    #                  :id - id of the main input tag for the element
    #                  :class - css class of the frame for the element
    #                  :required - true if value is mandatory
    #
    # Return nothing
    def initialize(parent_element, name, options)
      @parent = parent_element
      @name = name
      @options = options
    end

    # Clone the current element in a parallel tree
    #
    # parent_element - container for the clone tree
    #
    # Return the new element for the clone tree.
    def clone(parent_element)
      self.class.new(parent_element, name, options)
    end

    # Type of element.
    # Used in setting the CSS class for the element.
    # Es: multiplier, sequence, section, string, ...
    #
    # Return a String
    def type
      ty = self.class.name.split('::').last.downcase
      (ty =~ /element$/) ? ty[0...-7] : ty
    end

    # Name of the element within the survey
    #
    # Return a String in format \w+(\.\w+)*
    # Es: surv1.tennis.tournaments.master
    def path_name
      @parent ? "#{@parent.path_name}.#{name}" : name
    end

    # The survey is the root of the element tree that
    # this element belongs to.
    #
    # Return a Survey.
    def survey
      parent ? parent.survey : self
    end

    # text that introduces the field.
    # TODO: Based on I18n rules
    #
    # Return a String
    def label
      Element.i18n(options[:label], :"survey.#{path_name}", :"survey.attributes.#{name}", name.humanize)
    end

    # When instantiated, can this element be changed, or
    # anyway input?
    # Default value: false
    #
    # Return true if this element can be changed, false otherwise.
    def readonly?
      options[:readonly] ? options[:readonly] : parent ? parent.readonly? : false
    end

    # The default value that this element has when the survey
    # is instanciated (empty).
    # Every element has a characteristic default value.
    #
    # Return an Object
    def default_value
      # generally, elements contain string (except containers)
      ''
    end

    # Generate a simple representation of the element's value
    # i.e. hash, array or simple value
    #
    # Return an Object (generally a String, a Hash or an Array)
    def simple_out(b_value)
      # generally, elements contain string (except containers)
      b_value
    end

    # Update current value with a new value, returning
    # the current value updated.
    #
    # NOTE: Consider that the new value can be a partial value,
    # so it is not intended to replace the current value but only
    # to update it.
    # Besides, the new value is always a simple value (string, hash, array)
    # while the old value could be a higher structure (depending on the element).
    #
    # current_value     - current value for the element
    # new_partial_value - partial value having new information for the current value
    #
    # Return the new current value updated
    def update_field(current_value, new_partial_value)
      raise ImplementedBySubclassError, "must be implemented by subclass [#{element.class.name}]"
    end

    # Validates current value on element's rules.
    # Sets root_hob.errors on failed validations with dom_namer's id.
    #
    # current_value - current value for the element
    # dom_namer     - naming information for the element
    # root_hob      - Hob that corresponds to the Survey, and holds all errors
    #                 for the element tree
    #
    # Return nothing
    def validate_value(current_value, dom_namer, root_hob)
      raise ImplementedBySubclassError, "must be implemented by subclass [#{element.class.name}]"
    end

    # An element is identifiable if it needs an id in HTML rendering.
    # Generally, all elements are identifiable except sections.
    #
    # Return a boolean
    def identifiable?
      true
    end

    # A human-readable representation of obj.
    #
    # Return a String
    def inspect
      "#<#{self.class.name}:##{self.path_name}>"
    end

    # Search in I18n store a label from a set of keys.
    #
    # NOTE: This implementation does not allow specifying an explicit lowercase text
    # (unless it is the last key), because it is considered a I81n key and therefore
    # searched for in the I18n store. Since the search will fail, the previous value
    # is assumed.
    #
    # keys          - Array of String or Symbols.
    #                 items can be textual strings or I18n keys to search for, in priority order.
    #                 if a key is not in I18n format (all lowercase with no spaces),
    #                 that key is considered a true label and has priority over
    #                 next keys.
    #                 if a key is null, it is not considered in label search.
    #                 The last key should be a valid textual string.
    #
    # Return a String.
    def self.i18n(*keys)
      default_value = keys.pop.to_s
      keys.reverse.inject(default_value) {|text,key|
        if key.nil?
          text
        elsif key.to_s =~ /^[a-z][a-z_\d]*(\.[a-z][a-z_\d]*)*$/ # i18n key
          I18n.t(key, :default => text)
        else
          key.to_s
        end
      }
    end

  end
end
