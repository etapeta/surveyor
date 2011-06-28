class SurveysController < ApplicationController
  require 'surveyor'

  def index
    @surveys = Surveyor.parse File.read(Rails.root.join('config', 'all.survey'))
    @survey = if params[:survey]
      @surveys.detect {|s| s.name == params[:survey]}
    end
  end

end
