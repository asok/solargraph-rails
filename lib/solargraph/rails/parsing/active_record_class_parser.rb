module Solargraph
  module Rails
    module Parsing
      class ActiveRecordClassParser < RubyParser
        attr_reader :model_attrs, :module_names, :model_name, :table_name

        def initialize(path, file_contents:)
          @path         = path
          @model_attrs  = []
          @module_names = []

          super(file_contents: file_contents)
        end

        def parse
          on_comment do |comment|
            log_info "found comment #{comment}"

            col_name, col_type = col_with_type(comment)

            if valid_col_type?(col_type)
              append_current_location(name: col_name, type: col_type)
            else
              log_info 'could not find annotation in comment'
            end
          end

          on_module do |mod_name|
            log_info "found module #{mod_name}"

            @module_names << mod_name
          end

          on_class do |klass, superklass|
            log_info "found class: #{klass} < #{superklass}"

            if ['ActiveRecord::Base', 'ApplicationRecord'].include?(superklass)
              @model_name = klass
            else
              log_info "Unable to find ActiveRecord model from #{klass} #{superklass}"

              @model_attrs = [] # don't include anything from this file
            end
          end

          on_ruby_line do |line|
            matcher = associations_matchers.find do |m|
              m.match?(line)
            end

            if matcher
              append_current_location(name: matcher.name, type: matcher.type)
            end

            matcher = MetaSource::Association::TableNameMatcher.new

            if matcher.match?(line)
              @table_name = matcher.table_name
            end
          end

          super

          @parsed = true
        end
      end
    end

    def closure
      raise "Call parse first" unless @parsed

      Solargraph::Pin::Namespace.new(
        name: @module_names.join('::') + "::#{@model_name}"
      )
    end

    private

    def log_info(message)
      Solargraph::Logging.logger.info message
    end

    def associations_matchers
      [
        MetaSource::Association::BelongsToMatcher.new,
        MetaSource::Association::HasManyMatcher.new,
        MetaSource::Association::HasOneMatcher.new,
        MetaSource::Association::HasAndBelongsToManyMatcher.new
      ]
    end

    def col_with_type(line)
      line
        .gsub(/[\(\),:\d]/, '')
        .split
        .first(2)
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

      @model_attrs << attrs.merge(location: loc)
    end

    def valid_col_type?(col_type)
      PinCreator::TYPE_TRANSLATION.keys.include?(col_type)
    end
  end
end
