# frozen_string_literal: true

require_relative '../active_record_set_instruction'

class ActiveSet
  module Sorting
    class ActiveRecordStrategy
      def initialize(set, attribute_instructions)
        @set = set
        @attribute_instructions = attribute_instructions
        @set_instructions = attribute_instructions.map do |attribute_instruction|
          ActiveRecordSetInstruction.new(attribute_instruction, set)
        end
      end

      def execute
        return false unless @set.respond_to? :to_sql

        executable_instructions.reduce(@set) do |set, set_instruction|
          statement = set.merge(set_instruction.initial_relation)
          statement = statement.merge(order_operation_for(set_instruction))

          set_instruction.processed = true
          statement
        end
      end

      def executable_instructions
        return {} unless @set.respond_to? :to_sql

        @set_instructions.select do |set_instruction|
          attribute_model = set_instruction.attribute_model
          next false unless attribute_model
          next false unless attribute_model.respond_to?(:attribute_names)
          next false unless attribute_model.attribute_names.include?(set_instruction.attribute)

          true
        end
      end

      private

      # https://stackoverflow.com/a/44912964/2884386
      # Force null values to be sorted as if larger than any non-null value
      # ASC => [-2, -1, 1, 2, nil]
      # DESC => [nil, 2, 1, -1, -2]
      def order_operation_for(set_instruction)
        attribute_model = set_instruction.attribute_model

        arel_column = set_instruction.arel_column
        arel_direction = direction_operator(set_instruction.value)
        nil_sorter = arel_column.send(arel_direction == :asc ? :eq : :not_eq, nil)

        attribute_model.order(nil_sorter).order(arel_column.send(arel_direction))
      end

      def direction_operator(direction)
        return :desc if direction.to_s.downcase.start_with? 'desc'

        :asc
      end
    end
  end
end
