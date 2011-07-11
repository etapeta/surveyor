module Surveyor
  class StringElement < Element
    class HtmlRenderer < Surveyor::Element::HtmlRenderer
      def render_widget(output, object, dom_namer, options)
        # object is a string
        emit_tag output, 'input', {:name => dom_namer.name, :id => dom_namer.id, :value => object}
      end
    end

    def renderer
      HtmlRenderer.new(self)
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
      unless new_partial_value.is_a?(String)
        raise InvalidFieldMatchError, "#{path_name} must be a String"
      end
      new_partial_value
    end

    # validates current value on element's rules.
    # Sets root_hob.errors on failed validations with dom_namer's id.
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
