require 'test_helper'

class SheetParserTest < ActiveSupport::TestCase

  setup do
    @survey = Surveyor::Parser.define do
      survey 'survy' do
        sequence 'outer' do
          string 'greg'
          string 'lillo'
          multiplier 'actors' do
            string 'name'
          end
        end
      end
    end
  end

  test 'a sheet parser can accept direct options' do
    sheet_parser = Surveyor::SheetParser.new(@survey)

    sheet_parser.hidden true
    sheet_parser.monster false

    # options on base elements are under the key '',
    # because element.find('') => elements
    assert_equal({'' => {:monster => false, :hidden => true}}, sheet_parser.sheet)
  end

  test 'a sheet parser can accept options on children' do
    sheet_parser = Surveyor::SheetParser.new(@survey)

    sheet_parser.outer.required true
    sheet_parser.outer.valid true

    assert_equal({'outer' => {:required => true, :valid => true}}, sheet_parser.sheet)
  end

  test 'a sheet parser can accept options on descendants' do
    sheet_parser = Surveyor::SheetParser.new(@survey)

    sheet_parser.outer.greg.required true
    sheet_parser.outer do
      marked false
      actors do
        validate true
        name.hidden true
      end
    end

    assert_equal({
      "outer" => { :marked=>false },
      "outer.greg" => { :required=>true }, 
      "outer.actors" => { :validate=>true }, 
      "outer.actors.name" => { :hidden=>true }, 
    }, sheet_parser.sheet)
  end

  test 'a sheet parser enfades on wrong element names' do
    sheet_parser = Surveyor::SheetParser.new(@survey)

    assert_raise Surveyor::ParsingError do
      sheet_parser.zzzouter.greg.required true
    end
  end

end
