require File.dirname(__FILE__) + '/../test_helper'

require 'content_item'

class ContentItemTest < Test::Unit::TestCase

  # fixtures :secret_agents

  def test_tokenize_on_occurrence
    c = ContentItem.new
    s = "this is a test big test"
    res = c.tokenize_on_occurrence(s, "test", 1)

    assert_equal("this is a test big ", res[0])
    assert_equal("test", res[1])
    assert_equal("", res[2])

    c = ContentItem.new
    s = "this is a test big test"
    res = c.tokenize_on_occurrence(s, "test", 0)

    assert_equal("this is a ", res[0])
    assert_equal("test", res[1])
    assert_equal(" big test", res[2])
  end

  def test_tokenize_on_occurrence_with_no_matches
    c = ContentItem.new
    s = "this is a test big test"
    res = c.tokenize_on_occurrence(s, "bum", 1)

    assert_nil(res)
  end

  def test_multiline_tokenization
    c = ContentItem.new
    s = "test\nthis is a test\nhowdy"
    res = c.tokenize_on_occurrence(s, "test", 1)

    assert_equal("test\nthis is a ", res[0])
    assert_equal("test", res[1])
    assert_equal("\nhowdy", res[2])
  end
end
