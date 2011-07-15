module Surveyor
  #
  # Container that contains all survey elements.
  #
  # Possible options (with those of Element):
  #
  class Survey < Sequence
    #
    # Renderer for a Survey
    #
    class HtmlRenderer < Surveyor::Container::HtmlRenderer
      include ActionView::Helpers::FormTagHelper
      include ActionView::Helpers::JavaScriptHelper

      # Generate a HTML representation for the form tag that should
      # input survey data.
      #
      # object - Hob to render in the form
      # url - url to call on form submission
      # options - options for form.
      #
      # Return a String containing the HTML representation.
      def render_form(object, url, options)
        output = ActiveSupport::SafeBuffer.new

        html_options = {
          'action' => url,
          'accept-charset' => "UTF-8",
        }
        html_options['method'] = options[:method].to_s if options[:method]
        html_options[:enctype] = "multipart/form-data" if options[:multipart]
        # html_options["data-remote"] = true if options["remote"]

        # error messages explanation
        output.safe_concat(form_tag_html(html_options))
        if object.errors.any?
          emit_tag output, 'div', :class => 'error_explanation' do |output|
            defmsg = pluralize(object.errors.count, "error") + ' prohibited this survey from being saved:'
            emit_tag output, 'h2',
              I18n.t('survey.error_explanation', :count => object.errors.count, :default => defmsg)
            emit_tag output, 'ul' do |output|
              object.errors.full_messages.each do |msg|
                emit_tag output, 'li', msg
              end
            end
          end
        end

        # render survey elements
        render(output, ObjectStack.new(object.container, object))

        # render submit button
        action = 'Submit' # TODO: I18n
        emit_tag output, 'div', :class => 'buttons' do
          emit_tag output, 'input', :type => 'submit', :class => 'button', :value => action
        end

        output.safe_concat("</form>")
        output
      end

      # Render the survey templates.
      # A template is a HTML partial which can be used by
      # an element instance to update itself based on certain
      # element events.
      # Currently, only multiplier need to render templates.
      # All template are contained within a hidden div.
      #
      # options - options for the div containing the templates.
      #
      # Return a String containing the HTML representation for the templates div.
      def wrap_templates(options)
        output = ActiveSupport::SafeBuffer.new
        emit_tag(output, 'div', :id => "templates_#{options[:id] || element.name}", :class => 'hidden') do
          render_templates output, DomNamer.new(element.name, options[:id] || element.name)
        end
        output
      end

    end

    # Sheets for the survey.
    #
    # Return a Hash[String,Hash[Symbol,Object]].
    attr_reader :sheets

    # Initialize the survey.
    #
    # name - name of the survey.
    # options - options for the survey element.
    #
    # Return nothing.
    def initialize(name, options)
      super(nil, name, options)
      @sheets = {}
    end

    # Clone the survey in a parallel survey.
    # Inherited from Container.
    # NOTE: A cloned survey has no sheets.
    #
    # parent_element - container for the clone tree
    #                  it must be nil in this case.
    #
    # Return the new survey.
    def clone(parent_element)
      raise WrongParentError, 'surveys can only be cloned as outer element' if parent_element
      result = self.class.new(name, options.clone)
      elements.each do |elem|
        result.elements << elem.clone(result)
      end
      result
    end

    # Create a fake survey that represents the multiplier
    # elements.
    #
    # multiplier - multiplier to "clone"
    #
    # Return a new Survey.
    def self.clone_for_factor(multiplier)
      surv = self.new(multiplier.path_name.gsub('.','__'),
        multiplier.options.merge(:no_label => true, :inner => { :label_remove => multiplier.label_remove }))
      multiplier.elements.each do |elem|
        surv.elements << elem.clone(surv)
      end
      surv
    end

    # Merge survey elements' options with options specified in sheet.
    #
    # sheet - name of the sheet, if the sheet has been declared in the survey.
    #         but it can be a Hash, representing the whole sheet.
    #
    # Return a new survey with options merged.
    def apply_sheet(sheet)
      sheet = sheets[sheet] if sheet.is_a?(String)
      surv = clone(nil)
      sheet.each do |path,opts|
        element = surv.find(path)
        raise ElementNotFound, "'#{path}' not found" unless element
        element.options.merge!(opts)
      end
      surv
    end

    # A html expert that can render a HTML representation for the element.
    #
    # Return a Object that respond to :render(output, object_stack).
    def renderer
      @renderer ||= HtmlRenderer.new(self)
    end

    # Create the whole HTML representation for the survey.
    # It consists in the form tag and in a div tag that
    # contains the templates necessary for the survey.
    #
    # object       - hob that contains survey data (even subset, or superset)
    # sheet        - survey sheet name to apply, or nil if none
    # form_options - options for the tags
    #
    # Return a String containing the HTML code.
    def form_for(object, sheet = nil, form_options = {})
      survey = if sheet && sheets[sheet]
        apply_sheet(sheet)
      else
        self
      end
      # TODO: form_options can contain elements which should be hidden or readonly
      opts = survey.options.merge(form_options)
      survey.renderer.render_form(object, form_options[:url], opts) + survey.renderer.wrap_templates(opts)
    end

  end

end
