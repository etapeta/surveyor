module Surveyor
  #
  # Object that parses a survey DLS.
  #
  class Parser
    attr_reader :surveys

    # Parse a survey definition contained in a string.
    #
    # code - string containing the survey definition
    #        It can contain one or more surveys.
    #
    # Return a Survey, or an Array[Survey] if more are defined,
    # or nil if none is found.
    def self.parse_string(code)
      parser = self.new
      parser.instance_eval(code)
      parser.surveys.empty? ? nil : parser.surveys.size == 1 ? parser.surveys.first : parser.surveys
    end

    # Parse a survey definition contained in a stream.
    #
    # code - stream containing the survey definition
    #        It can contain one or more surveys.
    #
    # Return a Survey, or an Array[Survey] if more are defined,
    # or nil if none is found.
    def self.parse_stream(stream)
      parser = self.new
      parser.instance_eval(stream.read)
      parser.surveys.empty? ? nil : parser.surveys.size == 1 ? parser.surveys.first : parser.surveys
    end

    # Elaborate a survey definition.
    #
    # blk - proc containing the survey definition
    #       It can contain one or more surveys.
    #
    # Return a Survey, or an Array[Survey] if more are defined,
    # or nil if none is found.
    def self.define(&blk)
      parser = self.new
      parser.instance_exec(&blk)
      parser.surveys.empty? ? nil : parser.surveys.size == 1 ? parser.surveys.first : parser.surveys
    end

    # Initialize the parser.
    #
    # Return nothing.
    def initialize
      @surveys = []
    end

    # Declare the start of a survey definition.
    #
    # name    - name of the survey
    # options - options of the survey
    # blk     - proc that defines the survey elements.
    #
    # Return nothing.
    def survey(name, options = {}, &blk)
      surv = Surveyor::Survey.new(name, options)
      ContainerParser.new(surv).instance_exec(&blk) if blk
      @surveys << surv
    end

  end

  #
  # Parser for a sequence of elements.
  #
  class ContainerParser
    attr_reader :container

    # Initialize the container parser.
    #
    # container - container whose elements are to be parsed.
    #
    # Return nothing.
    def initialize(container)
      @container = container
    end

    # Declare the start of a section element.
    # See Section class.
    #
    # name    - name of the element
    # options - options of the element
    # blk     - proc that defines the contained elements.
    #
    # Return nothing.
    def section(name, options = {}, &blk)
      section = Section.new(@container, name, options)
      ContainerParser.new(section).instance_exec(&blk) if blk
      @container.elements << section
    end

    # Declare the start of a sequence element.
    # See Sequence class.
    #
    # name    - name of the element
    # options - options of the element
    # blk     - proc that defines the contained elements.
    #
    # Return nothing.
    def sequence(name, options = {}, &blk)
      seq = Sequence.new(@container, name, options)
      ContainerParser.new(seq).instance_exec(&blk) if blk
      @container.elements << seq
    end

    # Declare the start of a multiplier element.
    # See Multiplier class.
    #
    # name    - name of the element
    # options - options of the element
    # blk     - proc that defines the contained elements.
    #
    # Return nothing.
    def multiplier(name, options = {}, &blk)
      mult = Multiplier.new(@container, name, options)
      ContainerParser.new(mult).instance_exec(&blk) if blk
      @container.elements << mult
    end

    # Declare the a string element.
    # See StringElement class.
    #
    # name    - name of the element
    # options - options of the element
    #
    # Return nothing.
    def string(name, options = {})
      @container.elements << StringElement.new(@container, name, options)
    end

    # Declare the a radio element.
    # See RadioElement class.
    #
    # name    - name of the element
    # options - options of the element
    #
    # Return nothing.
    def radio(name, options = {})
      raise ParsingError, "missing :values option" unless options[:values]
      @container.elements << RadioElement.new(@container, name, options)
    end

    # Declare a survey sheet.
    #
    # name - name of the sheet
    # sheet - hash containing element path names indicizing set of options
    #
    # Return nothing
    def sheet(name, sheet = nil, &blk)
      raise ParsingError, "Only surveys can have sheets" unless @container.is_a?(Survey)
      if blk
        if sheet
          raise ParsingError, "Only one sheet can be declared in a sheet directive"
        end
        # parse immediately, but elements must have been declared before
        sheet_parser = SheetParser.new(@container)
        sheet_parser.instance_eval(&blk)
        @container.sheets[name] = sheet_parser.sheet
      else
        raise ParsingError, "In a sheet directive, sheet must be passed as a Hash" unless sheet.is_a?(Hash)
        @container.sheets[name] = sheet
      end
    end

  end

  # Object which parses sheet declaration
  class SheetParser
    attr_reader :element, :sheet, :parent

    def initialize(element, parent = nil)
      @element = element
      @parent = parent
      @sheet = {}
    end

    def root
      parent ? parent.root : self
    end

    def method_missing(m, *args, &block)
      if args.size == 1
        # option: generate the path
        raise ParsingError, "options can be assigned single values only" unless args.size == 1
        register_options(Hash[m.to_s.chomp('=').to_sym => args[0]])
        nil
      else
        # element name: recurse
        raise ParsingError, "elements cannot be assigned values" unless args.empty?
        elem = @element.find(m.to_s)
        raise ParsingError, "unknown element: #{m}" unless elem
        sp = SheetParser.new(elem, self)
        if block
          sp.instance_eval(&block)
          nil
        else
          sp
        end
      end
    end

    protected

    def register_options(options, elem_path = [])
      if parent
        parent.register_options(options, [element.name] + elem_path)
      else
        path_name = elem_path.join('.')
        sheet[path_name] = (sheet[path_name] || {}).merge(options)
      end
    end
  end

end
