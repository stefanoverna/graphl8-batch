require "graphql8"
require "promise.rb"

module GraphQL8
  module Batch
    BrokenPromiseError = ::Promise::BrokenError
    class NoExecutorError < StandardError; end

    def self.batch(executor_class: GraphQL8::Batch::Executor)
      begin
        GraphQL8::Batch::Executor.start_batch(executor_class)
        ::Promise.sync(yield)
      ensure
        GraphQL8::Batch::Executor.end_batch
      end
    end

    def self.use(schema_defn, executor_class: GraphQL8::Batch::Executor)
      schema = schema_defn.target
      if GraphQL8::VERSION >= "1.6.0"
        instrumentation = GraphQL8::Batch::SetupMultiplex.new(schema, executor_class: executor_class)
        schema_defn.instrument(:multiplex, instrumentation)
        if schema.mutation
          if Gem::Version.new(GraphQL8::VERSION) >= Gem::Version.new('1.9.0.pre3') &&
              schema.mutation.metadata[:type_class]
            require_relative "batch/mutation_field_extension"
            schema.mutation.fields.each do |name, f|
              field = f.metadata[:type_class]
              field.extension(GraphQL8::Batch::MutationFieldExtension)
            end
          else
            schema_defn.instrument(:field, instrumentation)
          end
        end
      else
        instrumentation = GraphQL8::Batch::Setup.new(schema, executor_class: executor_class)
        schema_defn.instrument(:query, instrumentation)
        schema_defn.instrument(:field, instrumentation)
      end
      schema_defn.lazy_resolve(::Promise, :sync)
    end
  end
end

require_relative "batch/version"
require_relative "batch/loader"
require_relative "batch/executor"
require_relative "batch/setup"
require_relative "batch/setup_multiplex"
