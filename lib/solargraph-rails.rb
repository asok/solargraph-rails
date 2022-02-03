# frozen_string_literal: true

require 'solargraph'
require 'solargraph/rails/version'
require_relative 'solargraph/rails/pin_creator'
require_relative 'solargraph/rails/ruby_parser'
require_relative 'solargraph/rails/files_loader'
require_relative 'solargraph/rails/meta_source/association/belongs_to_matcher'
require_relative 'solargraph/rails/meta_source/association/has_many_matcher'
require_relative 'solargraph/rails/meta_source/association/has_one_matcher'
require_relative 'solargraph/rails/meta_source/association/has_and_belongs_to_many_matcher'

module Solargraph
  module Rails
    class DynamicAttributes < Solargraph::Convention::Base
      def global yard_map
        Solargraph::Environ.new(pins: parse_models)
      end

      private

      def parse_models
        loader = FilesLoader.new(Dir[File.join(Dir.pwd, 'app', 'models', '**', '*.rb')])

        loader.map do |file, contents|
          PinCreator.new(file, contents).create_pins(schema_file_parser)
        end
      end

      def schema_file_parser
        @schema_file_parser ||= begin
          path = File.join(Dir.pwd, 'config', 'schema.rb')

          Parsing::SchemaFileParser.new(path, file_contents: File.read(path)) if File.exist?(path)
        end
      end
    end
  end
end


Solargraph::Convention.register Solargraph::Rails::DynamicAttributes
