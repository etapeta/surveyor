require 'test_helper'

class SurveyTest < ActiveSupport::TestCase

  setup do
    @survey = factory(:survey)
  end

  test 'an element has a path name' do
    wimbledon = @survey.elements[1].elements[0].elements[1].elements[2]
    assert_equal 'wimbledon', wimbledon.name
    assert_equal 'nested.tennis.tournaments.grand_slam.wimbledon', wimbledon.path_name
  end

  test 'any element can climb to its survey' do
    wimbledon = @survey.elements[1].elements[0].elements[1].elements[2]
    assert_same @survey, wimbledon.survey
  end

end
