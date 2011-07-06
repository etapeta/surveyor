module Surveyor
  class Sequence < Container

    class HtmlCoder < Surveyor::Element::HtmlCoder

      def emit(output, object, dom_namer, options)
        output.safe_concat '<div class="sequence">'
        output.safe_concat "<h2>#{element.label}</h2>"
        element.elements.each do |elem|
          elem.html_coder.emit(output, object.send(elem.name), dom_namer + elem, elem.options)
        end
        output.safe_concat "</div>"
      end

    end

    def html_coder
      HtmlCoder.new(self)
    end

  end
end
