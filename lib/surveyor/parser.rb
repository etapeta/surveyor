module Surveyor
  class Parser
    attr_reader :surveys

    def self.parse_string(code)
      parser = self.new
      parser.instance_eval(code)
      parser.surveys.empty? ? nil : parser.surveys.size == 1 ? parser.surveys.first : parser.surveys
    end

    def self.parse_stream(stream)
      parser = self.new
      parser.instance_eval(stream.read)
      parser.surveys.empty? ? nil : parser.surveys.size == 1 ? parser.surveys.first : parser.surveys
    end

    def self.define(&blk)
      parser = self.new
      parser.instance_exec(&blk)
      parser.surveys.empty? ? nil : parser.surveys.size == 1 ? parser.surveys.first : parser.surveys
    end

    def initialize
      @surveys = []
    end

    def survey(name, options = {}, &blk)
      surv = Surveyor::Survey.new(name, options)
      ContainerParser.new(surv).instance_exec(&blk) if blk
      @surveys << surv
    end

  end

  class ContainerParser
    attr_reader :container

    def initialize(container)
      @container = container
    end

    def string(name, options = {})
      @container.elements << StringElement.new(@container, name, options)
    end

  end

end