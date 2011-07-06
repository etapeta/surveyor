module Surveyor
  class StringElement < Element

    class HtmlCoder < Surveyor::Element::HtmlCoder

      def emit_widget(output, object, dom_namer, options)
        # object is a string
        output.safe_concat tag('input', {:name => dom_namer.name, :id => dom_namer.id, :value => object})
      end

    end

    def html_coder
      HtmlCoder.new(self)
    end

  end
end
