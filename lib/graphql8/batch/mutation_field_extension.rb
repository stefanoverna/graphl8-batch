module GraphQL8::Batch
  class MutationFieldExtension < GraphQL8::Schema::FieldExtension
    def resolve(object:, arguments:, **_rest)
      GraphQL8::Batch::Executor.current.clear
      begin
        ::Promise.sync(yield(object, arguments))
      ensure
        GraphQL8::Batch::Executor.current.clear
      end
    end
  end
end
