require 'test_helper'

class ParserTest < ActiveSupport::TestCase
  test "a survey definition can be parsed from a string" do
    result = Surveyor::Parser.parse_string('')
    assert_nil result
  end

  test "a survey definition can be parsed from a stream" do
    sin = StringIO.new('')
    result = Surveyor::Parser.parse_stream(sin)
    assert_nil result
  end

  test "a survey definition can be parsed from code" do
    result = Surveyor::Parser.define do
    end
    assert_nil result
  end

  test 'an empty survey can be declared' do
    result = Surveyor::Parser.define do
      survey 'empty' do
      end
    end
    assert_kind_of Surveyor::Survey, result
    assert_equal 'empty', result.name
  end

  test 'a list of surveys can be declared' do
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

  test 'a survey can be defined' do
    result = Surveyor::Parser.define do
      survey 'simplest' do
        string 'description'
      end
    end
    assert_equal 1, result.elements.size
    assert_kind_of Surveyor::StringElement, result.elements.first
  end

  test 'a survey can have nested sections' do
    result = Surveyor::Parser.define do
      survey 'nested' do
        section 'football_roles' do
          string 'goalkeeper'
          string 'defender'
          string 'midfielder'
          string 'forward'
        end
        section 'tennis_tournaments' do
          string 'open_usa'
          string 'roland_garros'
          section 'wimbledon' do
            string 'bjorn_borg'
            string 'rod_laver'
            string 'john_mcenroe'
            string 'boris_becker'
            string 'roger_federer'
            string 'rafael_nadal'
          end
          string 'open_australia'
          string 'master'
        end
      end
    end
    assert_equal 2, result.elements.size
    assert_equal 5, result.elements[1].elements.size
    assert_equal 6, result.elements[1].elements[2].elements.size
  end

  test 'a survey has sheets' do
    survey = Surveyor::Parser.define do
      survey 'survy' do
        sequence 'outer' do
          string 'greg'
          string 'lillo'
          multiplier 'actors' do
            string 'name'
          end
        end

        sheet 'first' do
          outer.hidden true
        end
        sheet 'last' do
          outer.greg.required true
          outer do
            marked false
            actors do
              validate true
              name.hidden true
            end
          end
        end
      end
    end

    assert_equal 2, survey.sheets.size

    # options declared in sheet are null in base survey
    assert_nil survey.find('outer').options[:hidden]
    assert_nil survey.find('outer').options[:marked]
    assert_nil survey.find('outer.greg').options[:required]
    assert_nil survey.find('outer.actors').options[:validate]
    assert_nil survey.find('outer.actors.name').options[:hidden]

    surv_hidden = survey.apply_sheet('first')
    # new options have been set
    assert_equal true, surv_hidden.find('outer').options[:hidden]
    # but old options are still null
    assert_nil surv_hidden.find('outer').options[:marked]

    surv_mangled = survey.apply_sheet('last')
    # new options have been set
    assert_equal false, surv_mangled.find('outer').options[:marked]
    assert_equal true, surv_mangled.find('outer.greg').options[:required]
    assert_equal true, surv_mangled.find('outer.actors').options[:validate]
    assert_equal true, surv_mangled.find('outer.actors.name').options[:hidden]
    # but old options are still null
    assert_nil surv_mangled.find('outer').options[:hidden]
  end

end
