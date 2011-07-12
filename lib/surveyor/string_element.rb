module Surveyor
  #
  # Element that allows the input of a generic string.
  # Options characteristic of this element:
  # :size - size (in characters) of the input tag
  # :autocomplete - true if tag supports autocomplete
  # :autofocus - true if input tag should have focus on page load
  # :maxlength - maximum number of characters allowed
  #
  class StringElement < Element
    #
    # Renderer for a string element
    #
    class HtmlRenderer < Surveyor::Element::HtmlRenderer
      # Render the HTML reresentation for inner part
      # of the frame that characterizes the string element.
      #
      # output - buffer in which the representation is put
      # object_stack - objectstack that represents the position
      #                within the survey instance tree
      #
      # Return nothing.
      def render_widget(output, object_stack)
        # object_stack.object is a string
        # element.options contains useful options
        tag_attributes = {
          :name => object_stack.dom_name,
          :id => object_stack.dom_id,
          :value => object_stack.object
        }
        tag_attributes[:size] = element.options[:size] if element.options[:size]
        tag_attributes[:autocomplete] = 'on' if element.options[:autocomplete]
        tag_attributes[:autofocus] = 'autofocus' if element.options[:autofocus]
        tag_attributes[:maxlength] = element.options[:maxlength] if element.options[:maxlength]
        tag_attributes[:pattern] = element.options[:regexp] if element.options[:regexp]
        tag_attributes[:placeholder] = element.options[:placeholder] if element.options[:placeholder]
        tag_attributes[:required] = 'required' if element.options[:required]
        tag_attributes[:readonly] = 'readonly' if element.readonly?

        emit_tag output, 'input', tag_attributes
      end
    end

    # A html expert that can render a HTML representation for the element.
    #
    # Return a Object that respond to :render(output, object_stack).
    def renderer
      HtmlRenderer.new(self)
    end

    # Update current value with a new value, returning
    # the current value updated.
    #
    # current_value     - [String] current value for the element
    # new_partial_value - [String] new value
    #
    # Return the new value
    def update_field(current_value, new_partial_value)
      unless new_partial_value.is_a?(String)
        raise InvalidFieldMatchError, "#{path_name} must be a String"
      end
      new_partial_value
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
      if options[:required] && current_value.blank?
        root_hob.mark_error(dom_namer, :not_present)
      elsif options[:regexp]
        unless current_value.blank? || Regexp.new(options[:regexp]).match(current_value)
          root_hob.mark_error(dom_namer, :not_matching)
        end
      end
    end

  end
end
