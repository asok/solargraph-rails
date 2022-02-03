module MetaSource
  class ColumnDefinitionMatcher
    attr_reader :col_type, :col_name

    RE = /t\.(integer|bigint|datetime|date|time|string|text|float|decimal|numeric|boolean|) ['"]([a-zA-Z0-9]+)["'])/.freeze

    def match?(line)
      match = RE.match?(line)

      if match
        @col_type = match[1]
        @col_name = match[2]

        true
      else
        false
      end
    end
  end
end
