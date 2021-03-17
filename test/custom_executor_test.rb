require_relative 'test_helper'

class GraphQL8::Batch::CustomExecutorTest < Minitest::Test
  class MyCustomExecutor < GraphQL8::Batch::Executor
    class << self
      attr_accessor :call_count
    end
    self.call_count = 0

    def around_promise_callbacks
      self.class.call_count += 1

      super
    end
  end

  class Schema < GraphQL8::Schema
    query ::QueryType
    mutation ::MutationType

    use GraphQL8::Batch, executor_class: MyCustomExecutor
  end

  def setup
    MyCustomExecutor.call_count = 0
  end

  def test_batch_accepts_custom_executor
    product = GraphQL8::Batch.batch(executor_class: MyCustomExecutor) do
      RecordLoader.for(Product).load(1)
    end

    assert_equal 'Shirt', product.title
    assert MyCustomExecutor.call_count > 0
  end

  def test_custom_executor_class
    query_string = '{ product(id: "1") { id } }'
    Schema.execute(query_string)

    assert MyCustomExecutor.call_count > 0
  end
end
