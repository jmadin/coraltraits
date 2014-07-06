class MethodologiesController < ApplicationController
  before_action :signed_in_user
  before_action :contributor, only: [:create]
  before_action :set_methodology, only: [:show, :edit, :update, :destroy, :remove_trait]

  def new
  	@methodology = Methodology.new
  end

  def create
  	@methodology = Methodology.new(methodology_params)
  	trait_ids =  params[:methodology][:traits_attributes]
  	trait_ids.keys().each do |k|
  		#puts id
  		#puts val
  		@methodology.traits << Trait.find(trait_ids[k]["id"])
  	end

  	#@traits = Trait.find(methodology_params[:traits_attributes])

  	#@methodology.traits << @traits
  	if @methodology.save
      redirect_to methodologies_path, flash: {success: "Methodology was successfully created." }
    else
      render action: 'new' 
    end
  end

  def index
  	@methodologies = Methodology.search(params[:search])
	#@corals = Coral.search(params[:search])
  	respond_to do |format|
      format.html
      format.csv { send_data @methodologies.to_csv }
      
    end    
  end

  def show

  end


  def edit
  end

  def update
    trait_ids =  params[:methodology][:traits_attributes]
    trait_ids.keys().each do |k|
      #puts id
      #puts val
      @methodology.traits << Trait.find(trait_ids[k]["id"])
    end

    if @methodology.update(methodology_params)
      redirect_to @methodology, flash: {success: "Methodology was successfully updated." }
    else
      render action: 'edit'
    end
  end

  def destroy
    @methodology.destroy
    respond_to do |format|
      format.html { redirect_to methodologies_path }
      format.json { head :no_content }
    end
  end

  def remove_trait
  	trait = Trait.find(params[:trait_id])
  	if @methodology.traits.delete(trait)
  		redirect_to @methodology, flash: {success: "Trait Removed"}
  	else
  		redirect_to @methodology, flash: {alert: "Cannot remove Trait"}
  	end
  end

  def export
    checked = params[:checked]
    methodologies = Methodology.where(:id => params[:checked])

    csv_string = CSV.generate do |csv|
      csv << ["methodology_id", "methodology_name", "method_description"]
      methodologies.each do |method|
        csv << [method.id, method.methodology_name, method.method_description]
      end
   	end

    send_data csv_string, 
      :type => 'text/csv; charset=iso-8859-1; header=present', :stream => true,
      :disposition => "attachment; filename=methodologies_#{Date.today.strftime('%Y%m%d')}.csv"
          
  end


  private
  	def set_methodology
      @methodology = Methodology.find(params[:id])
    end
  	
  	def methodology_params
  		params.require(:methodology).permit(:methodology_name, :method_description, :traits)
  	end
end