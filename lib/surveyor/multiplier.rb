module Surveyor
  class Multiplier < Container
    class HtmlCoder < Surveyor::Container::HtmlCoder
      include ActionView::Helpers::JavaScriptHelper

      def emit(output, object, dom_namer, options)
        raise InvalidFieldMatchError, 'object must be an array' unless object.is_a?(Array)
        # container div
        emit_tag(output, 'div',
          :id => dom_namer.id, :class => element.type, 'data-name' => dom_namer.name) do |output|
          # label for whole multiplier
          emit_tag output, 'h2', element.label unless element.options[:no_label]
          # existing elements
          object.each_with_index do |obj, idx|
            emit_tag(output, 'div', :class => 'factor', :id => "#{dom_namer.id}_#{idx}") do |output|
              mult_namer = dom_namer * idx
              element.elements.each do |elem|
                if elem.identifiable?
                  elem.html_coder.emit(output, obj.send(elem.name), mult_namer + elem, elem.options)
                else
                  elem.html_coder.emit(output, obj, mult_namer, elem.options)
                end
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

      def emit_templates(output, dom_namer)
        # render the template with special prefix
        emit_tag output, 'div', :id => "templ_#{element.path_name.gsub('.','__')}" do
          tmp_surv = Survey.clone_for_factor(element)
          tmp_surv.html_coder.emit(output,
            Hob.new(tmp_surv),
            DomNamer.new(":prefix:", ":prefix:"),
            tmp_surv.options)
        end
        # continue searching other templates
        element.elements.each do |elem|
          if elem.identifiable?
            elem.html_coder.emit_templates output, dom_namer + elem
          else
            elem.html_coder.emit_templates output, dom_namer
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
    def base_value
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

    # updates a base value with a new value, returning
    # the (possibly new) base value updated.
    def update_field(base_value, value)
      # base value should be an array of hobs,
      # while value should be an array of hashes
      raise InvalidFieldMatchError, "#{path_name} must be an Array" unless value.is_a?(Array)
      raise SmallerArrayError, "#{path_name} must be an Array with not less than #{base_value.size} items" if value.size < base_value.size
      to_be_removed = []
      (0...base_value.size).each do |idx|
        # TODO: manage deleted items
        if value[idx]['deleted']
          # puts "remove #{idx}th element: #{base_value[idx].inspect}"
          to_be_removed << idx
        else
          base_value[idx].update(value[idx])
        end
      end
      (base_value.size...value.size).each do |idx|
        unless value[idx]['deleted']
          hob = Hob.new(self)
          hob.update(value[idx])
          # puts "add #{base_value.size}th element: #{hob.inspect}"
          base_value << hob
        end
      end
      unless to_be_removed.empty?
        to_be_removed.reverse.each do |idx|
          base_value.delete_at(idx)
        end
      end
      base_value
    end

    # create a html expert that represents object as an element in HTML.
    def html_coder
      HtmlCoder.new(self)
    end

  end
end
