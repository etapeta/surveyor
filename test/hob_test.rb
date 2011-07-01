require 'test_helper'

class HobTest < ActiveSupport::TestCase
  setup do
    @survey = Surveyor::Parser.define do
      survey 'nested' do
        section 'football_roles' do
          string 'goalkeeper'
          string 'defender'
          string 'midfielder'
          string 'forward'
        end
        section 'tennis' do
          sequence 'tournaments' do
            string 'open_usa'
            string 'roland_garros'
            string 'wimbledon'
            string 'open_australia'
            string 'master'
          end
          sequence 'champions' do
            string 'bjorn_borg'
            string 'rod_laver'
            string 'john_mcenroe'
            string 'boris_becker'
            string 'roger_federer'
            string 'rafael_nadal'
          end
          multiplier 'players' do
            string 'name'
            multiplier 'won_against' do
              string 'name'
              string 'tournment'
              string 'when'
            end
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
