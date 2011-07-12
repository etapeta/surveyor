module Surveyor
  #
  # A sequence is a concrete container.
  # It is instanced into a Hob.
  #
  class Sequence < Container
    #
    # Renderer for a Sequence
    #
    class HtmlRenderer < Surveyor::Container::HtmlRenderer
    end

    # A html expert that can render a HTML representation for the element.
    #
    # Return a Object that respond to :render(output, object_stack).
    def renderer
      HtmlRenderer.new(self)
    end

  end
end
