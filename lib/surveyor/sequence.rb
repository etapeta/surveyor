module Surveyor
  class Sequence < Container
    class HtmlRenderer < Surveyor::Container::HtmlRenderer
    end

    def renderer
      HtmlRenderer.new(self)
    end

  end
end
