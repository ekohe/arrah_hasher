require "array_hasher/version"

require "array_hasher/formatter"

require 'csv'
require 'json'

module ArrayHasher
  class << self
    def new_formatter(cols)
      Formatter.new(cols)
    end

    def parse_format(definition)
      definition.map do |val|
        name, type, opts = val.to_s.split(':', 3)

        [
          (name && name.length > 0) ? name.to_sym : nil,
          (type && type.length > 0) ? type.to_sym : nil,
          parse_options(opts)
        ]
      end
    end

    def csv_each(path, ext_types = {}, &block)
      csv = CSV.open(path)
      formatter = new_formatter(parse_format(csv.gets))
      formatter.types.merge!(ext_types)
      csv.each { |line| block.call(formatter.parse(line)) }
    end

    private

    def parse_options(opts)
      return {} unless opts

      # NOTE:
      # Can not figure out how to use json type wrapped by '{}' in csv file head line.
      # So keep it and add another custom options wrapped by '()' here.
      if opts =~ /\A\{.*\}\z/
        JSON.parse(opts)
      elsif opts =~ /\A\((.*)\)\z/
        Hash[opts.match(/\A\((.*)\)\z/).captures.map { |s| s.split(':') }]
      else
        {}
      end
    end
  end
end
