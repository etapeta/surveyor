require 'test_helper'

class ObjectStackTest < ActiveSupport::TestCase

  setup do
    @hob = factory(:full_hob)
    @object_stack = Surveyor::ObjectStack.new(@hob.container, @hob)
    @survey = @hob.container
  end

  test 'an objectstack can be created from a survey hob' do
    assert_same @object_stack.element, @survey
    assert_same @object_stack.object, @hob
  end

  test 'an objectstack can be created from any inner hob' do
    # find a container within a section
    inner_hob = @hob.tournaments
    assert_kind_of Surveyor::Hob, inner_hob

    os = @object_stack + @survey.find('tennis.tournaments')
    assert_same @survey.find('tennis.tournaments'), os.element
    assert_same inner_hob, os.object

    # find an element of a multiplier
    inner_hob = @hob.players[1].won_against[1]
    assert_kind_of Surveyor::Hob, inner_hob

    os = @object_stack + @survey.find('tennis.players')
    os = os * 1
    hob = @survey.find('tennis.players.won_against')
    os = os + @survey.find('tennis.players.won_against')
    os = os * 1

    assert_same inner_hob, os.object
    assert_same @survey.find('tennis.players.won_against'), os.element

    # find a final (string) element
    os = os + @survey.find('tennis.players.won_against.name')

    assert_equal 'federer', os.object
    assert_same @survey.find('tennis.players.won_against.name'), os.element
  end

  test 'an objectstack always references its root object' do
    # find a container within a section
    os = @object_stack + @survey.find('tennis.tournaments')
    assert_equal @hob, os.root_object

    # find an element of a multiplier
    inner_hob = @hob.players[1].won_against[1]
    assert_kind_of Surveyor::Hob, inner_hob

    os = @object_stack + @survey.find('tennis.players')
    os = os * 1
    hob = @survey.find('tennis.players.won_against')
    os = os + @survey.find('tennis.players.won_against')
    os = os * 1

    assert_same inner_hob, os.object
    assert_same @survey.find('tennis.players.won_against'), os.element

    # find a final (string) element
    os = os + @survey.find('tennis.players.won_against.name')

    assert_equal 'federer', os.object
    assert_same @survey.find('tennis.players.won_against.name'), os.element
  end

end
