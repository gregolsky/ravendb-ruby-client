require 'ravendb'
require 'spec_helper'
require 'documents/hilo'

class HiloGeneratorTest < TestBase
  COLLECTION = "Products"

  def setup
    super
    @generator = HiloIdGenerator.new(@_store, @_current_database, COLLECTION)
  end

  def test_should_starts_from_1
    id = @generator.generate_document_id

    assert_equal(id, "Products/1-A")
  end

  def test_should_increment_by_1
    id = nil
    prev_id = nil

    loop do
      id = @generator.generate_document_id

      if !prev_id.nil?
        assert_equal(range(id) - range(prev_id), 1)
      end

      prev_id = id

      break if @generator.range.needs_new_range?
    end
  end

  def test_should_request_new_range
    max_id = nil

    loop do
      @generator.generate_document_id

      if max_id.nil?
        max_id = @generator.range.max_id
      end

      break if @generator.range.needs_new_range?
    end

    @generator.generate_document_id
    assert(@generator.range.min_id > max_id)
  end

  def teardown
    @generator.return_unused_range
    super
  end

  protected
  def range(document_id)
    document_id.gsub("#{COLLECTION}/", "").gsub("-A", "")
  end
end