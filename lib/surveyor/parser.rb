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

  end

end
