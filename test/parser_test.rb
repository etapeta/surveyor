require 'test_helper'

class ParserTest < ActiveSupport::TestCase
  test "can parse a survey definition from a string" do
    result = Surveyor::Parser.parse_string('')
    assert_nil result
  end

  test "can parse a survey definition from a stream" do
    sin = StringIO.new('')
    result = Surveyor::Parser.parse_stream(sin)
    assert_nil result
  end

  test "can parse a survey definition from code" do
    result = Surveyor::Parser.define do
    end
    assert_nil result
  end

  test 'parse an empty survey' do
    result = Surveyor::Parser.define do
      survey 'empty' do
      end
    end
    assert_kind_of Surveyor::Survey, result
    assert_equal 'empty', result.name
  end

  test 'parse a list of empty surveys' do
    result = Surveyor::Parser.define do
      survey 'empty1' do
      end
      survey 'empty2' do
      end
    end
    assert_kind_of Array, result
    assert_equal 'empty1', result.first.name
    assert_equal 'empty2', result.last.name
  end

  test 'parse the simplest survey' do
    result = Surveyor::Parser.define do
      survey 'simplest' do
        string 'description'
      end
    end
    assert_equal 1, result.elements.size
    assert_kind_of Surveyor::StringElement, result.elements.first
  end

end
