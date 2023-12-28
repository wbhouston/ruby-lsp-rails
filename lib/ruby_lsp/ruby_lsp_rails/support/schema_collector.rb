# typed: strict
# frozen_string_literal: true

module RubyLsp
  module Rails
    module Support
      class SchemaCollector < Prism::Visitor
        attr_reader :tables

        def initialize
          @tables = {}

          super
        end

        def visit_call_node(node)
          unless node.message == 'create_table'
            super
            return
          end

          arguments = node.arguments&.arguments
          return unless arguments

          first_argument = arguments.first
          return unless first_argument.is_a?(Prism::StringNode)
          @tables[arguments.first.content] = node.location
        end
      end
    end
  end
end
