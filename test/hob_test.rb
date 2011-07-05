require 'test_helper'

class HobTest < ActiveSupport::TestCase

  setup do
    @hob = factory(:hob)
  end

  test "a hob can be created from a survey" do
    assert_not_nil @hob
  end

  test 'a hob can be created from a survey and initialized with a hash of data' do
    hob = factory(:hob, Surveyor::Parser.define {
      survey 'small' do
        string 'first'
        section 'body' do
          string 'middle'
        end
        string 'last'
      end
    }, { 'first' => 'a', 'last' => 'z' })
    assert_equal Hash["first"=>"a", "middle"=>"", "last"=>"z"], hob.to_h
  end

  test "creation" do
    assert_not_nil @hob
  end

  test 'generates an interface' do
    # simple element
    assert @hob.respond_to?(:goalkeeper)
    assert @hob.respond_to?("goalkeeper=")
    assert_equal '', @hob.goalkeeper
    # sequence
    assert @hob.respond_to?(:tournaments)
    assert @hob.respond_to?('tournaments=')
    assert_kind_of Surveyor::Hob, @hob.tournaments
    assert !@hob.tournaments.respond_to?(:wimbledon)
    assert @hob.tournaments.grand_slam.respond_to?(:wimbledon)
    assert_equal '', @hob.tournaments.grand_slam.wimbledon
    # multiplier
    assert @hob.respond_to?(:players)
    assert_equal [], @hob.players
    assert @hob.respond_to?('players=')
  end

  test 'update simple' do
    # load the hob with a hash
    form_data = {
      'goalkeeper' => 'zoff',
      'defender' => 'nesta',
      'midfielder' => 'pirlo',
      'forward' => 'rossi',
    }
    @hob.update(form_data)
    assert_equal 'zoff', @hob.goalkeeper
    assert_equal '', @hob.tournaments.grand_slam.wimbledon
    assert_equal '', @hob.tournaments.master
  end
  end

end
