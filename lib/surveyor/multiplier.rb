module Surveyor
  #
  # A Multiplier is a Sequence which can be replicated
  # multiple times.
  #
  # Options available:
  # :add_label - label for Add button
  # :remove_label - label for Remove button
  #
  class Multiplier < Container
    #
    # Multiplier's rendered
    #
    class HtmlRenderer < Surveyor::Container::HtmlRenderer
      include ActionView::Helpers::JavaScriptHelper

      # Generate a HTML representation for the multiplier
      #
      # output       - output buffer
      # object_stack - stack of the element instances being rendered
      #
      # Return nothing
      def render(output, object_stack)
        return if element.options[:killed] || element.elements.empty?
        raise InvalidFieldMatchError, 'object must be an array' unless object_stack.object.is_a?(Array)
        # container div
        emit_tag(output, 'div',
          :id => object_stack.dom_id, :class => element.type, 'data-name' => object_stack.dom_name) do |output|
          # label for whole multiplier
          emit_tag output, 'h2', element.label unless element.options[:no_label]
          # existing elements
          object_stack.object.each_with_index do |obj, idx|
            emit_tag(output, 'div', :class => 'factor', :id => "#{object_stack.dom_id}_#{idx}") do |output|
              obj_stack = object_stack * idx
              element.elements.each do |elem|
                elem.renderer.render(output, obj_stack + elem)
              end
              emit_tag output, 'div', :class => 'mult_remover' do
                output << link_to_function(element.label_remove, 'removeFactor(this)')
              end
            end
          end
          # multiplier link
          emit_tag output, 'div', :class => 'actions' do
            output << link_to_function(element.label_add,
              "addFactor('templ_#{element.path_name.gsub('.','__')}', this)")
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
        # render the template with special prefix
        emit_tag output, 'div', :id => "templ_#{element.path_name.gsub('.','__')}" do
          tmp_surv = Survey.clone_for_factor(element)
          tmp_surv.renderer.render(output,
            ObjectStack.new(tmp_surv, Hob.new(tmp_surv), nil, DomNamer.new(":prefix:", ":prefix:")))
        end
        # continue searching other templates
        element.elements.each do |elem|
          if elem.identifiable?
            elem.renderer.render_templates output, dom_namer + elem
          else
            elem.renderer.render_templates output, dom_namer
          end
        end
      end

    end

    # Label for action to add new multiplier items
    def label_add
      Element.i18n(options[:label_add], :"survey.label_add", 'Add')
    end

    # Label for action to remove existing multiplier items
    def label_remove
      Element.i18n(options[:label_remove], :"survey.label_remove", 'Remove')
    end

    # The default value that this element has when the survey
    # is instanciated (empty).
    # Inherited from Element.
    #
    # Since this element resembles an ordered list of hashes,
    # the base element is an empty list. At runtime, the list
    # will be filled with hobs (that will be initialized with
    # the elements of this container).
    #
    # Return a Object (an Array, precisely)
    def default_value
      []
    end

    # Generate a simple representation of the element's value
    # i.e. hash, array or simple value.
    # For a general container, the result is a Hash.
    #
    # b_value - object to extract data from
    #
    # Return an Array (for a multiplier).
    def simple_out(b_value)
      # a multiplier generates an array of hashes from an array of hobs
      b_value.collect do |b_item|
        accepted_elements.inject(Hash[]) do |hash,elem|
          if b_item.respond_to?(elem.name)
            hash[elem.name] = elem.simple_out(b_item.send(elem.name))
          end
          hash
        end
      end
    end

    # Update current value with a new value, returning
    # the current value updated.
    # For a general container, current_value is a Hob and new_partial_value
    # is a Hash.
    #
    # current_value     - current value for the element
    # new_partial_value - partial value having new information for the current value
    #
    # Return the new current value updated
    def update_field(current_value, new_partial_value)
      unless new_partial_value.is_a?(Array)
        raise InvalidFieldMatchError, "#{path_name} must be an Array"
      end
      if new_partial_value.size < current_value.size
        raise SmallerArrayError, "#{path_name} must be an Array with not less than #{current_value.size} items"
      end
      to_be_removed = []
      (0...current_value.size).each do |idx|
        # TODO: manage deleted items
        if new_partial_value[idx]['deleted']
          # puts "remove #{idx}th element: #{current_value[idx].inspect}"
          to_be_removed << idx
        else
          current_value[idx].update(new_partial_value[idx])
        end
      end
      (current_value.size...new_partial_value.size).each do |idx|
        unless new_partial_value[idx]['deleted']
          hob = Hob.new(self)
          hob.update(new_partial_value[idx])
          # puts "add #{current_value.size}th element: #{hob.inspect}"
          current_value << hob
        end
      end
      unless to_be_removed.empty?
        to_be_removed.reverse.each do |idx|
          current_value.delete_at(idx)
        end
      end
      current_value
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
      current_value.each_with_index do |obj, idx|
        # reflects validations on elements
        mult_namer = dom_namer * idx
        accepted_elements.each do |elem|
          elem.validate_value obj.send(elem.name), mult_namer + elem, root_hob
        end
      end
    end

    # A html expert that can render a HTML representation for the element.
    #
    # Return a Object that respond to :render(output, object_stack).
    def renderer
      HtmlRenderer.new(self)
    end

  end
end
