require_relative 'test_helper'

class GraphQL8::BatchTest < Minitest::Test
  def test_batch
    product = GraphQL8::Batch.batch do
      RecordLoader.for(Product).load(1)
    end
    assert_equal 'Shirt', product.title
  end

  def test_nested_batch
    promise1 = nil
    promise2 = nil

    product = GraphQL8::Batch.batch do
      promise1 = RecordLoader.for(Product).load(1)
      GraphQL8::Batch.batch do
        promise2 = RecordLoader.for(Product).load(1)
      end
      promise1
    end

    assert_equal 'Shirt', product.title
    assert_equal promise1, promise2
    assert_nil GraphQL8::Batch::Executor.current
  end
end
