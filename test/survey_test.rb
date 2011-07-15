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

  test 'an element can climb to its survey' do
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

  test 'a container finds itself when searched by an empty string' do
    assert_equal @survey, @survey.find('')
    tournaments = @survey.find('tennis.tournaments')
    assert_equal tournaments, tournaments.find('')
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

  test 'element labels can be customized' do
    I18n.backend.store_translations :en, {
      :survey => {
        :path_separator => ' | ',
        :error_format => "« %{attribute} » : %{message}",
        :attributes => {
          :goalkeeper => 'Portiere',
          :midfielder => 'NOT VALID'
        },
        :nested => {
          :football_roles => {
            # this label has priority vs :attributes:midfielder
            :midfielder => 'Centrocampista'
          }
        }
      },
      :extra => {
        :one => 'ONE'
      }
    }
    survey = factory(:survey)

    string_elem = survey.find('football_roles.goalkeeper')
    assert_equal 'Portiere', string_elem.label

    string_elem = survey.find('football_roles.midfielder')
    assert_equal 'Centrocampista', string_elem.label

    survey = Surveyor::Parser.define do
      survey 'mult' do
        multiplier 'many' do
          string 'one', :label => 'extra.one'
          string 'two'
        end
      end
    end

    string_elem = survey.find('many.one')
    assert_equal 'ONE', string_elem.label
  end

  test 'multiplier can have action labels customized' do
    I18n.backend.store_translations :en, {
      :survey => {
        :label_add => 'ADD'
      },
      :extra => {
        :remove => 'REMOVE'
      }
    }

    survey = Surveyor::Parser.define do
      survey 'mult' do
        multiplier 'many', :label_remove => 'extra.remove' do
          string 'one'
          string 'two'
        end
      end
    end

    multiplier = survey.find('many')
    assert_equal 'ADD', multiplier.label_add
    assert_equal 'REMOVE', multiplier.label_remove
  end

  test 'a survey can be merged options from a sheet' do
    base_survey = Surveyor::Parser.define do
      survey 'mult' do
        multiplier 'many', :label_remove => 'extra.remove' do
          string 'one'
          string 'two', :required => true
        end
      end
    end

    sheet = {
      'many.one' => { :required => true },
      'many.two' => { :required => false }
    }

    survey = base_survey.clone(nil).apply_sheet(sheet)
    one = survey.find('many.one')
    assert_kind_of Surveyor::StringElement, one
    assert_equal true, one.options[:required]
    assert_equal false, survey.find('many.two').options[:required]
  end

  test 'a survey can have sheets declared within' do
    survey = Surveyor::Parser.define do
      survey 'mult' do
        multiplier 'many', :label_remove => 'extra.remove' do
          string 'one'
          string 'two', :required => true
        end

        sheet 'master', {
          'many.one' => { :required => true },
          'many.two' => { :required => false }
        }
      end
    end

    assert_kind_of Hash, survey.sheets['master']
    sheeted_survey = survey.apply_sheet(survey.sheets['master'])
    assert_equal true, sheeted_survey.find('many.one').options[:required]
    assert_nil survey.find('many.one').options[:required]
  end

end
