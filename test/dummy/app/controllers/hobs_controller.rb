class HobsController < ApplicationController
  before_filter :find_survey

  # GET /hobs
  def index
    nests = Nest.all.group_by(&:survey_name)
    @surveys = all_surveys.inject([]) {|list,surv|
      list << [surv, nests[surv.name] || []]
      list
    }
  end

  # GET /hobs/1
  def show
    @nest = Nest.find(params[:nest_id])
  end

  # GET /hobs/new
  def new
    @nest = nil
    @hob = Surveyor::Hob.new(@base_survey)
  end

  # POST /hobs
  def create
    @hob = Surveyor::Hob.new(@base_survey)
    @hob.update(params[@survey.name])
    nest = Nest.new(:survey_name => @survey.name)
    nest.document = @hob.to_h
    nest.save!
    redirect_to hobs_path
  end

  # GET /hobs/1/edit
  def edit
    @nest = Nest.find(params[:id])
    @hob = Surveyor::Hob.new(@base_survey, @nest.document)
  end

  # PUT /hobs/1
  def update
    @nest = Nest.find(params[:id])
    @hob = Surveyor::Hob.new(@survey, @nest.document)
    @hob.update(params[@survey.name])
    if @hob.valid?
      hob = Surveyor::Hob.new(@base_survey, @nest.document)
      hob.update(params[@survey.name])
      @nest.document = hob.to_h
      @nest.save!
      redirect_to hobs_path
    else
      render :action => :edit, :id => params[:id], :survey => params[:survey], :sheet => params[:sheet]
    end
  end

  private

  def find_survey
    logger.info ">>> Session: #{session.inspect}"
    if params[:survey]
      @base_survey = all_surveys.detect {|surv| surv.name == params[:survey] }
      @survey = if params[:sheet].blank?
        session[:sheet] = nil
        @base_survey
      else
        session[:sheet] = params[:sheet]
        @base_survey.apply_sheet(params[:sheet])
      end
    end
  end

end
