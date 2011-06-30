class NestsController < ApplicationController
  # GET /nests
  # GET /nests.xml
  def index
    @nests = Nest.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @nests }
    end
  end

  # GET /nests/1
  # GET /nests/1.xml
  def show
    @nest = Nest.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @nest }
    end
  end

  # GET /nests/new
  # GET /nests/new.xml
  def new
    @nest = Nest.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @nest }
    end
  end

  # GET /nests/1/edit
  def edit
    @nest = Nest.find(params[:id])
  end

  # POST /nests
  # POST /nests.xml
  def create
    @nest = Nest.new(params[:nest])

    respond_to do |format|
      if @nest.save
        format.html { redirect_to(@nest, :notice => 'Nest was successfully created.') }
        format.xml  { render :xml => @nest, :status => :created, :location => @nest }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @nest.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /nests/1
  # PUT /nests/1.xml
  def update
    @nest = Nest.find(params[:id])

    respond_to do |format|
      if @nest.update_attributes(params[:nest])
        format.html { redirect_to(@nest, :notice => 'Nest was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @nest.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /nests/1
  # DELETE /nests/1.xml
  def destroy
    @nest = Nest.find(params[:id])
    @nest.destroy

    respond_to do |format|
      format.html { redirect_to(nests_url) }
      format.xml  { head :ok }
    end
  end
end
