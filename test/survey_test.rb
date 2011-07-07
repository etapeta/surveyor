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

  test 'a container can find an inner element by relative path' do
    wimbledon = @survey.find('tennis.tournaments.grand_slam.wimbledon')
    assert_same @survey.elements[1].elements[0].elements[1].elements[2], wimbledon
    tournaments = @survey.find('tennis.tournaments')
    assert_same @survey.elements[1].elements[0], tournaments
    w = tournaments.find('grand_slam.wimbledon')
    assert_same w, wimbledon
  end

  test 'a survey can contain a multiplier' do
    survey = Surveyor::Parser.define do
      survey 'mult' do
        multiplier 'many' do
          string 'one'
          string 'two'
        end
      end
    end
  end

  test 'an element can be cloned' do
    survey = factory(:survey)

    string_elem = survey.find('football_roles.goalkeeper')
    string_clone = string_elem.clone(nil)
    assert_equal 'goalkeeper', string_clone.name
    assert_nil string_clone.parent
    assert_equal string_elem.options, string_clone.options
    assert_equal 'goalkeeper', string_clone.path_name

    section_elem = survey.find('football_roles')
    section_clone = section_elem.clone(nil)
    assert_equal 'football_roles', section_clone.name
    assert_equal section_elem.options, section_clone.options
    assert_nil section_clone.parent
    assert_equal 'football_roles', section_clone.path_name

    surv_clone = survey.clone(nil)
    assert_equal 'nested', surv_clone.name
    assert_nil surv_clone.parent
    assert_equal survey.options, surv_clone.options
    assert_equal 'nested', surv_clone.path_name
  end

end
