require 'test_helper'

class StringElementTest < ActiveSupport::TestCase

  test 'parse the simplest survey' do
    result = Surveyor::Parser.define do
      survey 'simplest' do
        string 'description'
      end
    end
    assert_equal 1, result.elements.size
    assert_kind_of Surveyor::StringElement, result.elements.first
    assert_equal 'description', result.elements.first.name
    assert_equal result, result.elements.first.parent
    assert result.elements.first.options.empty?
  end

  test 'parse two strings' do
    result = Surveyor::Parser.define do
      survey 'simplest' do
        string 'description'
        string 'subject'
      end
    end
    assert_equal 2, result.elements.size
    assert_kind_of Surveyor::StringElement, result.elements.first
    assert_kind_of Surveyor::StringElement, result.elements.last
    assert_equal 'description', result.elements.first.name
    assert_equal 'subject', result.elements.last.name
    assert_equal result, result.elements.first.parent
    assert_equal result, result.elements.last.parent
  end

end
