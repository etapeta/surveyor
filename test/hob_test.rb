require 'test_helper'

class HobTest < ActiveSupport::TestCase

  setup do
    @hob = factory(:hob)
  end
        end
      end
    end
    @hob = Surveyor::Hob.new(@survey)
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
    assert @hob.tournaments.respond_to?(:wimbledon)
    assert_equal '', @hob.tournaments.wimbledon
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
    assert_equal '', @hob.tournaments.wimbledon
  end

end
