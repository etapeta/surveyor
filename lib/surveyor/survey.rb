module Surveyor
  class Survey < Section

    def initialize(name, options)
      super(nil, name, options)
    end

    class HtmlCoder < Surveyor::Element::HtmlCoder
      include ActionView::Helpers::FormTagHelper

      def generate(survey, object, options)
        singular = ActiveModel::Naming.singular(object)
        html_options = if object.respond_to?(:persisted?) && object.persisted?
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

        dom_namer = DomNamer.new(survey.name, options[:id] || survey.name)
        output = ActiveSupport::SafeBuffer.new
        output.safe_concat(tag('div', {:class => 'survey', :id => dom_namer.id}, true))
        output.safe_concat(form_tag_html(html_options))
        survey.elements.each do |elem|
          elem.emit_html(output, object.send(elem.name), dom_namer + elem, elem.options)
        end
        output.safe_concat("</form>")
        output.safe_concat("</div>")
        output
      end
    end

    def form_for(object, form_options = {})
      # TODO: form_options can contain elements which should be hidden or readonly
      HtmlCoder.new.generate(self, object, options)
    end

  end

end
