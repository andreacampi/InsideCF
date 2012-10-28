class DeasController < ApplicationController
  # GET /deas
  # GET /deas.json
  def index
    @deas = Dea.all.order_by('index ASC')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @deas }
    end
  end

  # GET /deas/1
  # GET /deas/1.json
  def show
    @dea = Dea.find(params[:id])
    @droplets = @dea.droplets.order_by('app_id ASC')

    respond_to do |format|
      format.html { render 'show', :layout => 'two_columns' }
      format.json { render json: @dea }
    end
  end

  # GET /deas/new
  # GET /deas/new.json
  def new
    @dea = Dea.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @dea }
    end
  end

  # GET /deas/1/edit
  def edit
    @dea = Dea.find(params[:id])
  end

  # POST /deas
  # POST /deas.json
  def create
    @dea = Dea.new(params[:dea])

    respond_to do |format|
      if @dea.save
        format.html { redirect_to @dea, notice: 'Dea was successfully created.' }
        format.json { render json: @dea, status: :created, location: @dea }
      else
        format.html { render action: "new" }
        format.json { render json: @dea.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /deas/1
  # PUT /deas/1.json
  def update
    @dea = Dea.find(params[:id])

    respond_to do |format|
      if @dea.update_attributes(params[:dea])
        format.html { redirect_to @dea, notice: 'Dea was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @dea.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /deas/1
  # DELETE /deas/1.json
  def destroy
    @dea = Dea.find(params[:id])
    @dea.destroy

    respond_to do |format|
      format.html { redirect_to deas_url }
      format.json { head :no_content }
    end
  end
end
