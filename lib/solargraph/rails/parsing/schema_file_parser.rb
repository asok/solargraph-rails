module Solargraph
  module Rails
    module Parsing
      class SchemaFileParser < RubyParser
        def initialize(path, file_contents:)
          @path   = path
          @tables = {}

          super(file_contents: file_contents)
        end

        def tables
          parse unless @parsed

          @tables
        end

        private

        def parse
          @tables.clear

          on_ruby_line do |line|
            matcher = MetaSource::TableDefinitionMatcher.new

            if matcher.match?(line)
              @current_table_name = matcher.table_name
            else
              matcher = MetaSource::ColumnDefinitionMatcher.new

              if matcher.match?(line)
                append_current_location(name: matcher.col_name, type: matcher.col_type)
              end
            end
          end

          super

          @parsed = true
        end

        def append_current_location(attrs)
          loc = Solargraph::Location.new(
            @path,
            Solargraph::Range.from_to(
              current_line_number,
              0,
              current_line_number,
              current_line_length - 1
            )
          )

          @tables[@current_table_name] = []
          @tables[@current_table_name] << attrs.merge(location: loc)
        end
      end
    end
  end
end
