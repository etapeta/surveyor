module Surveyor
  #
  # Element that allows the input of a long text.
  #
  # Options for this element:
  # :cols         - visible width of a text-area
  # :rows         - visible number of rows in a text-area
  # :required     - input data cannot be left empty
  # :readonly     - data cannot be entered
  #
  class TextElement < Element
    #
    # Renderer for a text element
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
        }
        tag_attributes[:cols] = element.options[:cols] if element.options[:cols]
        tag_attributes[:rows] = element.options[:rows] if element.options[:rows]
        tag_attributes[:readonly] = 'readonly' if element.readonly?

        emit_tag output, 'textarea', h(object_stack.object), tag_attributes
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
    # Sets errors on failed validations under local_id key.
    #
    # current_value - current value for the element
    # local_id      - key that uniquely identifies the value within the tree data
    # errors        - Errors for the tree data
    #
    # Return nothing
    def validate_value(current_value, local_id, errors)
      if options[:required] && current_value.blank?
        errors[local_id] << "survey.errors.not_present"
      end
    end

  end
end
