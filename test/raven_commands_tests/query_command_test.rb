require 'ravendb'
require 'securerandom'
require 'minitest/autorun'
require 'requests/request_executor'
require 'requests/request_helpers'
require 'documents/conventions'
require 'documents/document_query'
require 'database/operations'
require 'database/commands'
require 'spec_helper'

class QueryCommandTest < TestBase
  query = "FROM Testing WHERE Tag = 'Products'"
  @_index_query = nil
  @_conventions = nil

  def setup
    super 

    @_request_executor.execute(RavenDB::PutDocumentCommand.new('Products/10', {
      "Name" => "test", 
      "@metadata" => {
        "Raven-Ruby-Type": 'Product', 
        "@collection": 'Products'
      }
    }))

    @_conventions = @_store.conventions
    @_index_query = RavenDB::IndexQuery.new(query, 128, 0 , nil, {"wait_for_non_stale_results" => true})
  end

  def should_do_query
    result = @_request_executor.execute(RavenDB::QueryCommand.new(@_index_query, @_conventions))

    assert(result.Results.first.key?('Name'))
    assert_equals('test', result.Results.first["Name"])
  end

  def should_query_only_metadata
    result = @_request_executor.execute(RavenDB::QueryCommand.new(@_index_query, @_conventions, nil, true))

    refute(result.Results.first.key?('Name'))
  end

  def should_query_only_documents
    result = @_request_executor.execute(RavenDB::QueryCommand.new(@_index_query, @_conventions, nil, nil, true))
    
    refute(result.Results.first.key?('@metadata'))
  end

  def should_fail_with_no_existing_index
    assert_raises do
      @_index_query = RavenDB::IndexQuery.new("FROM IndexIsNotExists WHERE Tag = 'Products", 128, 0 , nil, {"wait_for_non_stale_results" => true})
      @_request_executor.execute(RavenDB::QueryCommand.new(@_index_query, @_conventions))
    end
  end
end  