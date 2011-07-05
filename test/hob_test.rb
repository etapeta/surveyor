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

  test 'a hob can be represented as a hash' do
    assert_equal Hash[
      'goalkeeper' => '',
      'defender' => '',
      'midfielder' => '',
      'forward' => '',
      'tournaments' => {
        'master' => '',
        'grand_slam' => {
          'open_usa' => '',
          'roland_garros' => '',
          'wimbledon' => '',
          'open_australia' => '',
        },
        'foro_italico' => '',
      },
      'champions' => {
        'bjorn_borg' => '',
        'rod_laver' => '',
        'john_mcenroe' => '',
        'boris_becker' => '',
        'roger_federer' => '',
        'rafael_nadal' => '',
      },
      'players' => [],
    ], @hob.to_h

    hob = factory(:hob, Surveyor::Parser.define {
      survey 'small' do
        string 'first'
        section 'body' do
          string 'middle'
        end
        string 'last'
      end
    })
    assert_equal Hash["first"=>"", "middle"=>"", "last"=>""], hob.to_h
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

  test 'update accepts a hash on a sequence' do
    form_data = {
      'tournaments' => { 'foro_italico' => 'panatta' }
    }
    @hob.update(form_data)
    assert_equal 'panatta', @hob.tournaments.foro_italico
    assert_equal '', @hob.tournaments.master
  end

  test 'update refuses anything except a hash on a sequence' do
    form_data = {
      'tournaments' => 'any'
    }
    assert_raise(Surveyor::InvalidFieldMatchError) do
      @hob.update(form_data)
    end
  end

  test 'update refuses unknown fields' do
    form_data = {
      'tournaments' => {'any' => 'pippo'}
    }
    assert_raise(Surveyor::UnknownFieldError) do
      @hob.update(form_data)
    end
  end

  test 'update accepts only adequate fields in inner sequences' do
    form_data = {
      'tournaments' => { 'grand_slam' => {'wimbledon' => 'becker', 'roland_garros' => 'nadal' }}
    }
    @hob.update(form_data)
    assert_equal 'becker', @hob.tournaments.grand_slam.wimbledon
    assert_equal '', @hob.tournaments.grand_slam.open_usa
  end

  test 'update accepts a string on a standard string field' do
    form_data = {
      'forward' => 'messi',
      'tournaments' => { 'grand_slam' => {'roland_garros' => 'nadal' }}
    }
    @hob.update(form_data)
    assert_equal 'messi', @hob.forward
    assert_equal 'nadal', @hob.tournaments.grand_slam.roland_garros
  end

  test 'update cannot accept anything except a string on a standard string field' do
    form_data = {
      'forward' => {'roland_garros' => 'nadal' },
    }
    assert_raise(Surveyor::InvalidFieldMatchError) do
      @hob.update(form_data)
    end
  end

  test 'update accepts an array on a multiplier' do
    form_data = {
      'players' => [{'name' => 'nadal' },{'name' => 'federer'}]
    }
    @hob.update(form_data)
    assert_kind_of Array, @hob.players
    assert_kind_of Surveyor::Hob, @hob.players.first
    assert_equal 2, @hob.players.size
    assert_equal 'nadal', @hob.players.first.name
    assert_equal [], @hob.players.first.won_against
    assert_equal 'federer', @hob.players.last.name
  end

  test 'update accepts an additional array on a multiplier' do
    form_data = {
      'players' => [
        {
          'name' => 'nadal',
          'won_against' => [
            {'name' => 'federer'},
            {'name' => 'djokovic'}
          ],
        },
        {
          'name' => 'federer',
          'won_against' => [
            {'name' => 'murray'},
            {'name' => 'tsonga', 'tournament' => 'wimbledon'},
            {'name' => 'djokovic'}
          ],
        }
      ]
    }
    @hob.update(form_data)
    assert_equal 2, @hob.players.size
    assert_equal 2, @hob.players[0].won_against.size
    assert_equal 3, @hob.players[1].won_against.size
    assert_equal '', @hob.players[0].won_against.first.tournament
    assert_equal 'wimbledon', @hob.players[1].won_against[1].tournament
  end

  test 'update cannot accept anything except an array on a multiplier' do
    form_data = {
      'players' => {'name' => 'nadal' }
    }
    assert_raise(Surveyor::InvalidFieldMatchError) do
      @hob.update(form_data)
    end
  end

  test 'update adds multiplier elements' do
    form_data = {
      'players' => [
        {
          'name' => 'nadal',
          'won_against' => [
            {'name' => 'federer'},
            {'name' => 'djokovic', 'tournament' => 'roland_garros'}
          ],
        },
        {
          'name' => 'federer',
          'won_against' => [
            {'name' => 'murray'},
            {'name' => 'tsonga', 'tournament' => 'wimbledon'},
            {'name' => 'djokovic'}
          ],
        }
      ]
    }
    @hob.update(form_data)

    form_data = {
      'players' => [
        {
          'name' => 'nadal',
          'won_against' => [
            {'name' => 'federer', 'tournament' => 'open_australia'}, # add a string value
            {'name' => 'fish'},
            # add another item
            {'name' => 'del_potro'},
          ],
        },
        {
          # empty hash, means no update
        },
      ],
    }
    @hob.update(form_data)
    assert_equal 3, @hob.players.first.won_against.size
    assert_equal 'open_australia', @hob.players.first.won_against[0].tournament
    assert_equal 'fish', @hob.players.first.won_against[1].name
    assert_equal 'del_potro', @hob.players.first.won_against[2].name
    # other previous fields have not been touched
    assert_equal 'murray', @hob.players[1].won_against[0].name
    assert_equal '', @hob.players[1].won_against[0].tournament
    assert_equal 'federer', @hob.players[1].name
    assert_equal 'roland_garros', @hob.players[0].won_against[1].tournament
  end

  test 'update deletes removed multiplier elements' do
    form_data = {
      'players' => [
        {
          'name' => 'nadal',
          'won_against' => [
            {'name' => 'federer'},
            {'name' => 'djokovic', 'tournament' => 'roland_garros'}
          ],
        },
        {
          'name' => 'federer',
          'won_against' => [
            {'name' => 'murray'},
            {'name' => 'tsonga', 'tournament' => 'wimbledon'},
            {'name' => 'djokovic'}
          ],
        }
      ]
    }
    @hob.update(form_data)

    form_data = {
      'players' => [
        {
          # remove nadal
          'deleted' => 'yes',
        },
        {
          # change federer's matches
          'won_against' => [
            {}, # keep match against murray
            {'deleted' => 'x'}, # remove match against tsonga
            {}, # keep match against djokovic
            {'deleted' => 'y'}, # remove never added match
            {'deleted' => 'w'}, # remove never added match
            # add another item
            {'name' => 'del_potro'},
            {'deleted' => 'z'}, # remove never added match
          ],
        },
        {
          # add murray
          'name' => 'murray'
        },
      ],
    }
    @hob.update(form_data)

    # check that nadal has been removed
    assert_equal 2, @hob.players.size
    assert_equal 'federer', @hob.players[0].name
    assert_equal 'murray', @hob.players[1].name
    #check that match against tsonga has been deleted
    assert_equal 3, @hob.players[0].won_against.size
    assert_equal 'murray', @hob.players[0].won_against[0].name
    assert_equal 'djokovic', @hob.players[0].won_against[1].name
    assert_equal 'del_potro', @hob.players[0].won_against[2].name
  end

  test 'a hob can set and read its fields' do
    hob = factory(:hob, Surveyor::Parser.define {
      survey 'small' do
        string 'first'
        section 'body' do
          string 'middle'
        end
        string 'last'
      end
    })

    hob.first = 'one'
    hob['last'] = 'finally'
    assert_equal 'one', hob['first']
    assert_equal 'finally', hob.last
  end

end
