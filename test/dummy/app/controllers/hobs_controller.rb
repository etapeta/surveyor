class HobsController < ApplicationController
  before_filter :find_survey

  # GET /nests
  # GET /nests.xml
  def index
    nests = Nest.all.group_by(&:survey_name)
    @surveys = all_surveys.inject(Hash[]) {|hash,surv|
      hash[surv] = nests[surv.name] || []
      hash
    }
  end

  # GET /nests/1
  # GET /nests/1.xml
  def show
    @nest = Nest.find(params[:nest_id])
  end

  # GET /nests/new
  # GET /nests/new.xml
  def new
    @nest = nil
    @hob = Surveyor::Hob.new(@survey)
  end

  # POST /nests
  # POST /nests.xml
  def create
    @hob = Surveyor::Hob.new(@survey)
    @hob.update(params[@survey.name])
    nest = Nest.new(:survey_name => @survey.name)
    nest.document = @hob.to_h
    nest.save!
    redirect_to hobs_path
  end

  # GET /nests/1/edit
  def edit
    @nest = Nest.find(params[:id])
    @hob = Surveyor::Hob.new(@survey, @nest.document)
  end

  # PUT /nests/1
  # PUT /nests/1.xml
  def update
    @nest = Nest.find(params[:id])
    @hob = Surveyor::Hob.new(@survey, @nest.document)
    @hob.update(params[@survey.name])
    if @hob.valid?
      @nest.document = @hob.to_h
      @nest.save!
      redirect_to hobs_path
    else
      render :action => :edit
    end
  end

  private

  def find_survey
    @survey = params[:survey] && all_surveys.detect {|surv| surv.name == params[:survey] }
  end

end
