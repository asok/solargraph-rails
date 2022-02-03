module MetaSource
  class TableNameMatcher
    attr_reader :table_name

    def match?(line)
      match = /\s+self\.table_name\s+=\s+([a-z_0-9]*)/.match(line)

      if match
        @table_name = match[1]

        true
      else
        false
      end
    end
  end
end
