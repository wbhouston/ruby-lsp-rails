# typed: strict
# frozen_string_literal: true

require "ruby_lsp/addon"

require_relative "rails_client"
require_relative "hover"
require_relative "code_lens"
require_relative "support/schema_collector"

module RubyLsp
  module Rails
    class Addon < ::RubyLsp::Addon
      extend T::Sig

      sig { returns(RailsClient) }
      def client
        @client ||= T.let(RailsClient.new, T.nilable(RailsClient))
      end

      sig { override.params(message_queue: Thread::Queue).void }
      def activate(message_queue)
        client.check_if_server_is_running!
        parse_schema
      end

      sig { override.void }
      def deactivate; end

      # Creates a new CodeLens listener. This method is invoked on every CodeLens request
      sig do
        override.params(
          uri: URI::Generic,
          dispatcher: Prism::Dispatcher,
        ).returns(T.nilable(Listener[T::Array[Interface::CodeLens]]))
      end
      def create_code_lens_listener(uri, dispatcher)
        CodeLens.new(uri, dispatcher)
      end

      sig do
        override.params(
          nesting: T::Array[String],
          index: RubyIndexer::Index,
          dispatcher: Prism::Dispatcher,
        ).returns(T.nilable(Listener[T.nilable(Interface::Hover)]))
      end
      def create_hover_listener(nesting, index, dispatcher)
        Hover.new(client, @tables, nesting, index, dispatcher)
      end

      sig { override.returns(String) }
      def name
        "Ruby LSP Rails"
      end

      private

      sig { override.void }
      def parse_schema
        project_root = T.let(
          Bundler.with_unbundled_env { Bundler.default_gemfile }.dirname,
          Pathname,
        )
        path = project_root.join('db', 'schema.rb')
        parse_result = Prism::parse_file(path.to_s)

        return unless parse_result.success?

        schema_collector = Support::SchemaCollector.new
        parse_result.value.accept(schema_collector)

        @tables = schema_collector.tables
      end
    end
  end
end
