module Surveyor
  class Multiplier < Container
    class HtmlRenderer < Surveyor::Container::HtmlRenderer
      include ActionView::Helpers::JavaScriptHelper

      def render(output, object_stack)
        raise InvalidFieldMatchError, 'object must be an array' unless object_stack.object.is_a?(Array)
        # container div
        emit_tag(output, 'div',
          :id => object_stack.dom_id, :class => element.type, 'data-name' => object_stack.dom_name) do |output|
          # label for whole multiplier
          emit_tag output, 'h2', element.label unless element.options[:no_label]
          # existing elements
          object_stack.object.each_with_index do |obj, idx|
            emit_tag(output, 'div', :class => 'factor', :id => "#{object_stack.dom_id}_#{idx}") do |output|
              obj_stack = object_stack.mult(obj, idx)
              element.elements.each do |elem|
                elem.renderer.render(output, obj_stack + elem)
              end
              emit_tag output, 'div', :class => 'mult_remover' do
                output << link_to_function(Multiplier.action_labels[:remove], 'removeFactor(this)')
              end
            end
          end
          # multiplier link
          emit_tag output, 'div', :class => 'actions' do
            output << link_to_function(Multiplier.action_labels[:add],
              "addFactor('templ_#{element.path_name.gsub('.','__')}', this)")
          end
        end
      end

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

    def self.action_labels
      {   # TODO: from I18n
        :add => 'Add',
        :remove => 'Remove'
      }
    end

    # The default value that this element has when the survey
    # is instanciated (empty).
    #
    # Since this element resembles an ordered list of hashes,
    # the base element is an empty list. At runtime, the list
    # will be filled with hobs (that will be initialized with
    # the elements of this container).
    def default_value
      []
    end

    # generates a simple representation of the element's value
    # i.e. hash, array or simple value
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

    # updates current value with a new value, returning
    # the current value updated.
    #
    # NOTE: For a multiplier, old_value should be an array of hobs,
    # while new_partial_value should be an array of hashes
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

    # validates current value on element's rules.
    # Sets root_hob.errors on failed validations with dom_namer's id.
    def validate_value(current_value, dom_namer, root_hob)
      current_value.each_with_index do |obj, idx|
        # reflects validations on elements
        mult_namer = dom_namer * idx
        accepted_elements.each do |elem|
          elem.validate_value obj.send(elem.name), mult_namer + elem, root_hob
        end
      end
    end

    # create a html expert that represents object as an element in HTML.
    def renderer
      HtmlRenderer.new(self)
    end

  end
end
