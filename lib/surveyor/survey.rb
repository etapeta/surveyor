module Surveyor
  class Survey < Section

    def initialize(name, options)
      super(nil, name, options)
    end

    class HtmlCoder < Surveyor::Element::HtmlCoder
      include ActionView::Helpers::FormTagHelper

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

      def emit(output, object, dom_namer, options)
        output.safe_concat(tag('div', {:class => element.type, :id => dom_namer.id}, true))
        # TODO: title for survey?
        element.elements.each do |elem|
          if elem.identifiable?
            elem.html_coder.emit(output, object.send(elem.name), dom_namer + elem, elem.options)
          else
            elem.html_coder.emit(output, object, dom_namer, elem.options)
          end
        end
        output.safe_concat("</div>")
      end

    end

    # create a html expert that represents object as an element in HTML.
    def html_coder
      HtmlCoder.new(self)
    end

    def form_for(object, form_options = {})
      # TODO: form_options can contain elements which should be hidden or readonly
      html_coder.emit_form(object, form_options[:url], options.merge(form_options))
    end

  end

end
