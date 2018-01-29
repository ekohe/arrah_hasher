require 'time'

module ArrayHasher
  class Formatter
    attr_accessor :cols, :types

    REGEXP_EMPTY = /\A\s*\z/

    TYPES = {
      int: Proc.new {|v| (v.nil? || v =~ REGEXP_EMPTY) ? nil : v.gsub(/[^\d]+/, '').to_i },
      float: Proc.new {|v| (v.nil? || v =~ REGEXP_EMPTY) ? nil :  v.gsub(/[^\d\.]+/, '').to_f },
      string: Proc.new {|v| v.to_s },
      time: Proc.new {|v| v ? Time.parse(v) : nil }
    }

    # cols:
    #   [
    #     [], # ignore this col
    #     [:name, :string],
    #     [:amount, :int],
    #     [:type], # don't change val
    #     [:other, Proc {|v| v.to_i % 2}]  # convert val by proc
    #     [:all, nil, range: 0..-1]
    #   ]
    def initialize(cols)
      @types = TYPES.clone

      @cols = cols.map do |name, type, opts|
        [
          name ? name.to_sym : nil,
          (type.nil? || type.is_a?(Proc)) ? type : type.to_sym,
          (opts || {}).each_with_object({}) {|kv, r| r[kv[0].to_sym] = kv[1] }
        ]
      end
    end

    def define_type(type, &block)
      types[type.to_sym] = block
    end

    def parse(arr)
      cols.each_with_index.each_with_object({}) do |col_and_index, result|
        col_opts, index = col_and_index
        name, type, opts = col_opts
        opts ||= {}
        next if name.nil?

        if name == :date
          type = make_proc_for_date(opts[:format]) if opts[:format]
        end

        range = opts[:range] || index
        val = range.is_a?(Array) ? arr.slice(*range) : arr[range]

        result[name] = if type.is_a?(Proc)
          type.call(val)
        elsif type && (block = types[type.to_sym])
          block.call(val)
        else
          val
        end
      end
    end

    private

    # format:
    #  'm-y': Sep-16
    def make_proc_for_date(format)
      case format
      when 'm-y'
        Proc.new do |v|
          month, year = v.split('-')
          if year.length == 2
            year = DateTime.now.year.to_s[0..1] + year
          end
          date = "#{month} #{year}"
          Date.strptime(date, "%b %Y")
        end
      end
    end
  end
end

