module MetaSource
  class TableDefinitionMatcher
    attr_reader :table_name

    def match?(line)
      match = /\bcreate_table[ (]["']([a-zA-Z0-9]+)["']/.match(line)

      if match
        @table_name = match[1]

        true
      else
        false
      end
    end
  end
end
