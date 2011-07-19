class ApplicationController < ActionController::Base
  protect_from_forgery

  def all_surveys
    @all_surveys ||= Surveyor::Parser.parse_string(File.read(Rails.root.join('config', 'all.survey'))).sort_by(&:name)
  end

end
