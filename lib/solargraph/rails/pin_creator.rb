# frozen_string_literal: true

require 'active_support/core_ext/string/inflections'

module Solargraph
  module Rails
    class PinCreator
      attr_reader :contents, :path

      TYPE_TRANSLATION = {
        'decimal'  => 'BigDecimal',
        'integer'  => 'Integer',
        'date'     => 'Date',
        'datetime' => 'ActiveSupport::TimeWithZone',
        'string'   => 'String',
        'boolean'  => 'Boolean',
        'text'     => 'String',
      }.freeze

      def initialize(path, contents)
        @path     = path
        @contents = contents
      end

      def create_pins(schema_file_parser)
        main_parser = Parsing::ActiveRecordClassParser.new
        main_parser.parse

        if main_parser.model_attrs.empty?
          return unless schema_file_parser

          schema_file_parser.tables.fetch(main_parser.table_name, []).each do |model_attrs|
            schema_file_parser.model_attrs.each do |attr|
              instantiate_pin_method(attr, main_parser.closure)
            end
          end
        else
          main_parser.model_attrs.each do |attr|
            instantiate_pin_method(attr, main_parser.closure)
          end
        end
      end

      private

      def instantiate_pin_method(attr, closure)
        Solargraph::Pin::Method.new(
          name:      attr.fetch(:name),
          comments:  "@return [#{TYPE_TRANSLATION.fetch(attr.fetch(:type), attr.fetch(:type))}]",
          location:  attr.fetch(:location),
          closure:   closure,
          scope:     :instance,
          attribute: true
        )
      end
    end
  end
end
