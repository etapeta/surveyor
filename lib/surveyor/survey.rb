module Surveyor
  class Survey < Section
    class HtmlCoder < Surveyor::Container::HtmlCoder
      include ActionView::Helpers::FormTagHelper
      include ActionView::Helpers::JavaScriptHelper

      def emit_form(object, url, options)
        singular = ActiveModel::Naming.singular(object)
        html_options = {}
        if object.respond_to?(:persisted?) && object.persisted?
          {
            :class  => "edit",
            :id => options[:id] || ActionController::RecordIdentifier.dom_id(object, :edit),
            :method => :put
          }
        else
          {
            :class  => "new",
            :id => options[:id] || ActionController::RecordIdentifier.dom_id(object),
            :method => :post
          }
        end
        html_options['method'] = options[:method].to_s if options[:method]
        html_options[:enctype] = "multipart/form-data" if options[:multipart]
        html_options[:action]  = url
        html_options['accept-charset'] = "UTF-8"
        # html_options["data-remote"] = true if options["remote"]

        dom_namer = DomNamer.new(element.name, options[:id] || element.name)
        output = ActiveSupport::SafeBuffer.new
        output.safe_concat(form_tag_html(html_options))
        emit(output, object, dom_namer, options)

        # submit button
        action = 'Submit'
        output.safe_concat("<div class='buttons'><input type='submit' class='button' value='#{action}'/></div>")
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
          emit_templates output, DomNamer.new(element.name, options[:id] || element.name)
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
    def html_coder
      @html_coder ||= HtmlCoder.new(self)
    end

    def form_for(object, form_options = {})
      # TODO: form_options can contain elements which should be hidden or readonly
      opts = options.merge(form_options)
      html_coder.emit_form(object, form_options[:url], opts) + html_coder.wrap_templates(opts)
    end

    private

    def render_template(options)
      html_coder.emit_templates(options)
    end

  end

end
