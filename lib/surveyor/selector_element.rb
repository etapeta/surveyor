module Surveyor
  #
  # Element that allows the choice of one among a short set of elements.
  #
  # Options for this element:
  # :values       - (Array[String] | Array[Array[String]] | Proc) values to be provided.
  #                 if Proc, the block is evaluated resulting in an Array[String] or
  #                 Array[Array[String]].
  #                 Array[String] contains values that are also used (evaluated) as labels.
  #                 Array[Array[String]] contains pairs [label, value]
  #                 A label is evaluated as I18n if lowercase with dots and without spaces.
  # :other        - if true, last value is considered a "Other" alternative: when selected
  #                 it shows a string field (with no label)
  # :display_as   - :radio | :list (default)
  # :required     - input data cannot be left empty.
  #
  class SelectorElement < Element
    #
    # Renderer for a selector element
    #
    class HtmlRenderer < Surveyor::Element::HtmlRenderer
      # Render the HTML reresentation for inner part
      # of the frame that characterizes the selector element.
      #
      # output - buffer in which the representation is put
      # object_stack - objectstack that represents the position
      #                within the survey instance tree
      #
      # Return nothing.
      def render_widget(output, object_stack)
        # object_stack.object is a string
        # element.options contains useful options
        values = element.options[:values].nil? ? [] :
          element.options[:values].is_a?(Proc) ? element.options[:values].call : 
          element.options[:values]
        # TODO: manage readonly? flag
        values = values.collect {|v| [v, v] } if values.first.is_a?(String)
        values.unshift(['','']) unless element.options[:required]

        emit_tag output, 'div', :id => object_stack.dom_id, :class => 'options' do |output|
          if element.options[:display_as] == :radio
            # render selector as a set of radio buttons
            # to guarantee that a value is returned, use a hidden field
            emit_tag output, 'input', :type => 'hidden', :name => "#{object_stack.dom_name}[value]",
              :value => ''
            values.each do |val|
              tag_attributes = {
                :type => 'radio',
                :name => "#{object_stack.dom_name}[value]",
                :value => val.last
              }
              tag_attributes[:class] = 'other_trigger' if element.options[:other] && val == values.last
              tag_attributes[:checked] = 'checked' if object_stack.object['value'] == val.last
              emit_tag output, 'input', tag_attributes
              output << Element.i18n(val.first, val.first) << '<br>'.html_safe
            end
          else
            # render selector as a drop-down list
            emit_tag output, 'select', :name => "#{object_stack.dom_name}[value]" do |output|
              values.each do |val|
                tag_attributes = { :value => val.last }
                tag_attributes[:class] = 'other_trigger' if element.options[:other] && val == values.last
                tag_attributes[:selected] = 'selected' if object_stack.object['value'] == val.last
                emit_tag output, 'option', tag_attributes do |output|
                  output << Element.i18n(val.first, val.first)
                end
              end
            end
          end
          # render a hidden string element for possible other option
          tag_attributes = {
            :name => "#{object_stack.dom_name}[other]",
            :class => 'other',
            :value => object_stack.object['other'],
          }
          if values.empty? || !element.options[:other] || object_stack.object['value'] != values.last.last
            tag_attributes[:style] = 'display:none'
            tag_attributes[:value] = ''
          end
          emit_tag output, 'input', tag_attributes
        end
      end
    end

    # A html expert that can render a HTML representation for the element.
    #
    # Return a Object that respond to :render(output, object_stack).
    def renderer
      HtmlRenderer.new(self)
    end

    # The default value that this element has when the survey
    # is instanciated (empty).
    # Every element has a characteristic default value.
    #
    # Return an Object
    def default_value
      { 'value' => '', 'other' => '' }
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
    # current_value     - [Object] current value for the element
    # new_partial_value - [Object] new value
    #
    # Return the new value
    def update_field(current_value, new_partial_value)
      # TODO: manage :other option
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
      if options[:required] && current_value['value'].blank?
        errors[local_id] << "survey.errors.not_present"
      end
    end

  end
end
