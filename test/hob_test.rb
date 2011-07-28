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

  test 'a hob can be updated from a hash' do
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

  test "a hob's inner containers are hobs" do
    assert_kind_of Surveyor::Hob, @hob.tournaments.grand_slam
  end

  test 'a hob can access its container element' do
    grand_slam = @hob.tournaments.grand_slam
    assert_kind_of Surveyor::Hob, @hob.tournaments.grand_slam
    assert_equal 'grand_slam', grand_slam.container.name
    assert_equal 'nested', grand_slam.container.survey.name
  end

  test 'hobs can be initialized from any container (except sections?)' do
    survey = Surveyor::Parser.define do
      survey 'mult' do
        multiplier 'many' do
          string 'one'
          string 'two'
        end
      end
    end
    hob = Surveyor::Hob.new(survey.find('many'))
    assert_equal({ 'one' => '', 'two' => '' }, hob.to_h)
  end

  test 'a hob with required values has errors on missing fields' do
    survey = Surveyor::Parser.define do
      survey 'simple' do
        string 'one', :required => true
        string 'two'
      end
    end
    hob = Surveyor::Hob.new(survey)
    # by default, errors are empty. They are set after calling :valid?
    assert hob.errors.empty?

    result = hob.valid?
    assert_equal false, result
    assert_equal 1, hob.errors.size
    assert_equal ["survey.errors.not_present"], hob.errors['one']
    assert_include "One can't be blank", hob.errors.full_messages
  end

  test 'a hob has its errors reset after update' do
    survey = Surveyor::Parser.define do
      survey 'simple' do
        string 'one', :required => true
        string 'two'
      end
    end
    hob = Surveyor::Hob.new(survey, {})
    assert_equal false, hob.valid?
    assert_equal 1, hob.errors.size

    hob.update({})
    assert_equal 0, hob.errors.size
  end

  test 'a hob with regexp option accepts empty value unless :required' do
    survey = Surveyor::Parser.define do
      survey 'simple' do
        string 'one', :required => true
        string 'two', :regexp => '^a.+$'
      end
    end
    hob = Surveyor::Hob.new(survey, {'one' => '1', 'two' => '2'})
    assert_equal false, hob.valid?
    assert_equal 1, hob.errors.size
    assert_equal ['survey.errors.not_matching'], hob.errors['two']
    assert_include 'Two is not valid', hob.errors.full_messages

    hob.update({'one' => '1', 'two' => 'another'})
    assert_equal true, hob.valid?
    assert_equal 0, hob.errors.size
  end

  test 'a hob detects errors in inner structures' do
    survey = Surveyor::Parser.define do
      survey 'simple' do
        sequence 'mixed' do
          string 'one', :required => true
          string 'two'
        end
      end
    end
    hob = Surveyor::Hob.new(survey, {'mixed' => {'one' => '1', 'two' => '2'} })
    assert_equal true, hob.valid?

    hob.update({'mixed' => {'one' => '', 'two' => '2'} })
    assert_equal false, hob.valid?
    assert_equal ["survey.errors.not_present"], hob.errors[:"mixed.one"]
    assert_include "Mixed > One can't be blank", hob.errors.full_messages
  end

  test 'a hob detects error in inner sections' do
    survey = Surveyor::Parser.define do
      survey 'simple' do
        sequence 'mixed' do
          section 'main' do
            string 'one', :required => true
            string 'two'
          end
        end
      end
    end
    hob = Surveyor::Hob.new(survey, {'mixed' => {'one' => '1', 'two' => '2'} })
    assert_equal true, hob.valid?

    hob.update({'mixed' => {'one' => '', 'two' => '2'} })
    assert_equal false, hob.valid?
    assert_equal ["survey.errors.not_present"], hob.errors[:"mixed.one"]
  end

  test 'a hob detects error in multiplier items' do
    survey = Surveyor::Parser.define do
      survey 'simple' do
        multiplier 'mixed' do
          string 'one', :required => true
          string 'two'
        end
      end
    end
    hob = Surveyor::Hob.new(survey, {'mixed' => [{'one' => '1', 'two' => '2'}, {'one' => '', 'two' => '4'}] })
    assert_equal false, hob.valid?

    assert_equal ["survey.errors.not_present"], hob.errors[:"mixed.001.one"]
    assert_equal ["Mixed #2 > One can't be blank"], hob.errors.full_messages
  end

  test 'hob errors can be customized' do
    I18n.backend.store_translations :en, :survey => {
      :path_separator => ' | ',
      :error_format => "« %{attribute} » : %{message}",
      :attributes => {
        :one => 'Primus'
      }
    }
    survey = Surveyor::Parser.define do
      survey 'simple' do
        sequence 'mixed' do
          string 'one', :required => true
          string 'two'
        end
      end
    end
    hob = Surveyor::Hob.new(survey, {'mixed' => {'one' => '', 'two' => '2'} })
    assert_equal false, hob.valid?
    assert_include "« Mixed | Primus » : can't be blank", hob.errors.full_messages
  end

  test 'a hob can be inspected' do
    assert_equal 'Surveyor::Hob<survey>{goalkeeper:"",defender:"",midfielder:"",forward:"",tournaments:...,champions:...,players:...}', @hob.inspect
  end

  test 'a hob can generate a flat hash' do
    assert_equal Hash[
      "tournaments:grand_slam:open_australia" => "",
      "tournaments:grand_slam:roland_garros" => "",
      "tournaments:grand_slam:wimbledon" => "",
      "tournaments:grand_slam:open_usa" => "",
      "tournaments:master" => "",
      "tournaments:foro_italico" => "",
      "midfielder" => "",
      "defender" => "",
      "forward" => "",
      "goalkeeper" => "",
      "champions:rod_laver" => "",
      "champions:roger_federer" => "",
      "champions:john_mcenroe" => "",
      "champions:rafael_nadal" => "",
      "champions:bjorn_borg" => "",
      "champions:boris_becker" => "",
    ], @hob.to_flat_h

    # check with active multipliers items
    hob = factory(:full_hob)
    assert_equal Hash[
      "champions:bjorn_borg"=>"the best",
      "champions:boris_becker"=>"",
      "champions:john_mcenroe"=>"the genius",
      "champions:rafael_nadal"=>"the grit",
      "champions:rod_laver"=>"",
      "champions:roger_federer"=>"the perfection",
      "defender"=>"cannavaro",
      "forward"=>"rossi",
      "goalkeeper"=>"zoff",
      "midfielder"=>"pirlo",
      "players:000:name"=>"federer",
      "players:000:won_against:000:name"=>"nadal",
      "players:000:won_against:000:tournament"=>"open usa",
      "players:000:won_against:000:when"=>"2007",
      "players:000:won_against:001:name"=>"djokovic",
      "players:000:won_against:001:when"=>"2010",
      "players:000:won_against:001:tournament"=>"wimbledon",
      "players:001:name"=>"nadal",
      "players:001:won_against:000:name"=>"djokovic",
      "players:001:won_against:000:tournament"=>"open usa",
      "players:001:won_against:000:when"=>"2010",
      "players:001:won_against:001:name"=>"federer",
      "players:001:won_against:001:tournament"=>"wimbledon",
      "players:001:won_against:001:when"=>"2010",
      "tournaments:foro_italico"=>"2011",
      "tournaments:grand_slam:open_australia"=>"2010",
      "tournaments:grand_slam:open_usa"=>"2010",
      "tournaments:grand_slam:roland_garros"=>"2011",
      "tournaments:grand_slam:wimbledon"=>"2011",
      "tournaments:master"=>"2008",
    ], hob.to_flat_h
  end

  test 'a hob can be updated from a flat hash' do
    hob2 = Surveyor::Hob.new(@hob.container)
    hob2.update_flat(@hob.to_flat_h)
    assert_equal @hob, hob2

    hob = factory(:full_hob)
    hob2 = Surveyor::Hob.new(hob.container)
    hob2.update_flat(hob.to_flat_h)
    assert_equal hob, hob2
  end

end
