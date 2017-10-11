module Okapi
  class ImplicitConfig
    def write!(&block)
      File.open(filename, "w", &block)
    end

    def read!(*_)
      File.exists?(filename) ? File.read(filename) : ""
    end

    def filename
      File.join(Dir.home, ".okapi")
    end

    def inspect
      filename
    end
  end

  class ExplicitConfig
    attr_reader :filename

    def initialize(filename)
      @filename = filename
    end
    def write!(&block)
      File.open(@filename, "w", &block)
    end

    def read!(force: false)
      checkfile!(force) do |exists|
        exists ? File.read(@filename) : ""
      end
    end

    def checkfile!(force)
      if !File.exists?(@filename)
        if force
          yield false
        else
          raise Okapi::ConfigurationError, "Unable to find configuration file '#{@filename}`"
        end
      else
        yield true
      end
    end
  end

  class PersistentVariables
    def initialize(config)
      @config = config
      @variables = {}
    end

    def filename
      @config.filename
    end

    def read!(force: false)
      lines = @config.read!(force: force).split(/\n+/).map(&:strip).reject(&:empty?)
      @variables = lines.map { |l| l.split("=") }.to_h
    end

    def write!
      @config.write! do |file|
        file.write(@variables.entries.map { |entry| "#{entry.first}=#{entry.last}"}.join("\n"))
        file.write("\n")
      end
    end

    def load!
      read!
      @variables.each_pair do |k,v|
        ENV[k] = v
      end
    end

    def merge(lines)
      @variables = @variables.merge lines.map { |l| l.split("=") }.to_h
    end

    def delete_all!(list)
      original = @variables
      @variables = @variables.reject { |k| list.include? k }
      original.length - @variables.length
    end
  end
end
