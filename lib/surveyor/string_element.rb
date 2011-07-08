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

  end
end
