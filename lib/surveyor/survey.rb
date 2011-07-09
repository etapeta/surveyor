module Surveyor
  class Survey < Sequence
    class HtmlRenderer < Surveyor::Container::HtmlRenderer
      include ActionView::Helpers::FormTagHelper
      include ActionView::Helpers::JavaScriptHelper

      def render_form(object, url, options)
        output = ActiveSupport::SafeBuffer.new

        html_options = {
          'action' => url,
          'accept-charset' => "UTF-8",
        }
        html_options['method'] = options[:method].to_s if options[:method]
        html_options[:enctype] = "multipart/form-data" if options[:multipart]
        # html_options["data-remote"] = true if options["remote"]
        output.safe_concat(form_tag_html(html_options))

        # render survey elements
        render(output, object, DomNamer.start(element), options)

        # render submit button
        action = 'Submit' # TODO: I18n
        emit_tag output, 'div', :class => 'buttons' do
          emit_tag output, 'input', :type => 'submit', :class => 'button', :value => action
        end

        output.safe_concat("</form>")
        output
      end

      def wrap_templates(options)
        output = ActiveSupport::SafeBuffer.new
        emit_tag(output, 'div', :id => "templates_#{options[:id] || element.name}", :class => 'hidden') do
          # block for remove link
          emit_tag output, 'div', :class => 'mult_remover' do
            output << link_to_function(Multiplier.action_labels[:remove], 'removeFactor(this)')
          end
          render_templates output, DomNamer.new(element.name, options[:id] || element.name)
        end
        output
      end

    end

    def initialize(name, options)
      super(nil, name, options)
    end

    def clone(parent_element)
      raise WrongParentError, 'surveys can only be cloned as outer element' if parent_element
      result = self.class.new(name, options)
      elements.each do |elem|
        result.elements << elem.clone(result)
      end
      result
    end

    def self.clone_for_factor(multiplier)
      surv = self.new(multiplier.path_name.gsub('.','__'), multiplier.options.merge(:no_label => true))
      multiplier.elements.each do |elem|
        surv.elements << elem.clone(surv)
      end
      surv
    end

    # create a html expert that represents object as an element in HTML.
    def renderer
      @renderer ||= HtmlRenderer.new(self)
    end

    def form_for(object, form_options = {})
      # TODO: form_options can contain elements which should be hidden or readonly
      opts = options.merge(form_options)
      renderer.render_form(object, form_options[:url], opts) + renderer.wrap_templates(opts)
    end

    private

    def render_template(options)
      renderer.render_templates(options)
    end

  end

end
