module Surveyor
  class Sequence < Container
    class HtmlCoder < Surveyor::Container::HtmlCoder
    end

    def html_coder
      HtmlCoder.new(self)
    end

  end
end
