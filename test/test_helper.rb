# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = "test.com"

Rails.backtrace_cleaner.remove_silencers!

# Configure capybara for integration testing
require "capybara/rails"
Capybara.default_driver   = :rack_test
Capybara.default_selector = :css

# Run any available migration
ActiveRecord::Migrator.migrate File.expand_path("../dummy/db/migrate/", __FILE__)

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

class ActiveSupport::TestCase

  SURVEY_BLOCK = Proc.new do
    survey 'nested' do
      section 'football_roles' do
        string 'goalkeeper'
        string 'defender'
        string 'midfielder'
        string 'forward'
      end
      section 'tennis' do
        sequence 'tournaments' do
          string 'master'
          sequence 'grand_slam' do
            string 'open_usa'
            string 'roland_garros'
            string 'wimbledon'
            string 'open_australia'
          end
          string 'foro_italico'
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
            string 'tournament'
            string 'when'
          end
        end
      end
    end
  end

  HOB_DATA = {
    'goalkeeper' => 'zoff',
    'defender' => 'cannavaro',
    'midfielder' => 'pirlo',
    'forward' => 'rossi',
    'tournaments' => {
      'master' => '2008',
      'grand_slam' => {
        'open_usa' => '2010',
        'roland_garros' => '2011',
        'wimbledon' => '2011',
        'open_australia' => '2010'
      },
      'foro_italico' => '2011'
    },
    'champions' => {
      'bjorn_borg' => 'the best',
      'john_mcenroe' => 'the genius',
      'roger_federer' => 'the perfection',
      'rafael_nadal' => 'the grit'
    },
    'players' => [
      {
        'name' => 'federer',
        'won_against' => [
          {
            'name' => 'nadal',
            'tournament' => 'open usa',
            'when' => '2007'
          },
          {
            'name' => 'djokovic',
            'tournament' => 'wimbledon',
            'when' => '2010'
          },
        ]
      },
      {
        'name' => 'nadal',
        'won_against' => [
          {
            'name' => 'djokovic',
            'tournament' => 'open usa',
            'when' => '2010'
          },
          {
            'name' => 'federer',
            'tournament' => 'wimbledon',
            'when' => '2010'
          },
        ]
      },
    ]
  }

  def factory(sym, survey = nil, hvalues = nil)
    case sym
    when :hob
      survey ||= Surveyor::Parser.define(&SURVEY_BLOCK)
      Surveyor::Hob.new(survey, hvalues)
    when :full_hob
      survey ||= Surveyor::Parser.define(&SURVEY_BLOCK)
      Surveyor::Hob.new(survey, HOB_DATA)
    when :survey
      Surveyor::Parser.define(&SURVEY_BLOCK)
    end
  end

  def assert_include(item, container, message = nil)
    msg = "#{item.inspect} is not contained in #{container.inspect}"
    msg = "#{message}\n#{msg}" if message
    assert container.include?(item), msg
  end

end
