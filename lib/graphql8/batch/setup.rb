module GraphQL8::Batch
  class Setup
    class << self
      def start_batching(executor_class)
        GraphQL8::Batch::Executor.start_batch(executor_class)
      end

      def end_batching
        GraphQL8::Batch::Executor.end_batch
      end

      def instrument_field(schema, type, field)
        return field unless type == schema.mutation
        old_resolve_proc = field.resolve_proc
        field.redefine do
          resolve ->(obj, args, ctx) {
            GraphQL8::Batch::Executor.current.clear
            begin
              ::Promise.sync(old_resolve_proc.call(obj, args, ctx))
            ensure
              GraphQL8::Batch::Executor.current.clear
            end
          }
        end
      end
    end

    def initialize(schema, executor_class:)
      @schema = schema
      @executor_class = executor_class
    end

    def before_query(query)
      Setup.start_batching(@executor_class)
    end

    def after_query(query)
      Setup.end_batching
    end

    def instrument(type, field)
      Setup.instrument_field(@schema, type, field)
    end
  end
end
