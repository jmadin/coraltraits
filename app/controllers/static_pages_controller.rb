class StaticPagesController < ApplicationController

  before_action :editor, only: [:release, :meta, :show, :duplicate, :uploads]

  def home
    @mea = Measurement.all.size
    @obs = Observation.all.size
    
    @locations = Location.all
  end
  
  def help
  end

  def meta
    # params[:editor] = "ready_for_release" if params[:status].blank?
    query = Trait.all
    query = query.editor(params[:editor]) if not params[:editor].blank?
    query = query.where(:release_status => params[:release_status]) if not params[:release_status].blank?
    @traits = query.all
  end

  def release

    @traits = Trait.where(:release_status => "ready_for_release")
    @observations = Observation.where("private IS false AND id IN (?)", Measurement.where("trait_id IN (?)", @traits.map(&:id)).map(&:observation_id))

  end

  def show
    @trait = Trait.find(params[:id])
  end

  def uploads
  end

  def duplicate
    @trait = Trait.find(params[:id])
  end

  def about
  end

  def procedures
  end

  def editors
  end

  def contact
  end

  def export_location_trait
    
    traits = Trait.where("release_status IS ? OR release_status IS ?", "ready_for_release", "needs_work_before_release")
    # traits = Trait.where("trait_class IS NOT ?", "Contextual")
    locations = Location.all

    csv_string = CSV.generate do |csv|

      csv << ["location_name", "lat", "lon", "measurements"]
      temp = 0
      locations.each do |loc|
        temp = 0
        traits.sort_by{|t| t[:trait_name]}.each do |tra|

          temp = temp + Measurement.where("trait_id IS ?", tra.id).joins(:observation).where("location_id IS ?", loc.id).size
        end

        csv << [loc.location_name, loc.latitude, loc.longitude, temp]

      end
    end

    send_data csv_string, 
     :type => 'text/csv; charset=iso-8859-1; header=present', :stream => true,
     :disposition => "attachment; filename=location_#{Date.today.strftime('%Y%m%d')}.csv"
          
  end

  def export_specie_trait
    
    if signed_in? && current_user.editor?
      measurements = Measurement.joins(:trait).where("release_status IS ?", "ready_for_release")
    end
    
    # traits = Trait.where("release_status = ?", "ready_for_release")
    traits = Trait.where("trait_class != ?", "Contextual")
    species = Specie.all

    csv_string = CSV.generate do |csv|

      head = ["specie_name"]
      real = ["release"]
      temp = 0
      species.sort_by{|c| c[:specie_name]}.each do |cor|
        keep = [cor.specie_name]
        traits.sort_by{|t| t[:trait_name]}.each do |tra|
          if temp == 0
            head << tra.trait_name
            if tra.release_status == "ready_for_release"
              real << 1
            else
              real << 0
            end
          end
          keep << Measurement.where("trait_id = ?", tra.id).joins(:observation).where("specie_id = ?", cor.id).size
        end
        if temp == 0
          csv << head
          csv << real
        end
        temp = 1
        csv << keep
      end
    end

    send_data csv_string, 
     :type => 'text/csv; charset=iso-8859-1; header=present', :stream => true,
     :disposition => "attachment; filename=trait_coral_#{Date.today.strftime('%Y%m%d')}.csv"
          
  end

  def export_ready_trait
    
    traits = Trait.where("release_status = ?", "ready_for_release")

    csv_string = CSV.generate do |csv|

      csv << ["trait_name", "class", "description", "standard", "unit", "values", "value description", "measurements", "link"]
      traits.sort_by{|t| t[:trait_name]}.each do |tra|

        csv << [
          tra.trait_name, 
          tra.trait_class, 
          tra.trait_description, 
          tra.standard.standard_name, 
          tra.standard.standard_unit, 
          tra.traitvalues.collect(&:value_name).join(", "), 
          tra.traitvalues.map(&:value_description).join(", "), 
          tra.measurements.size, 
          # Observation.where(:id => tra.measurements.map(&:observation_id)).map(&:resource_id).uniq.join(", "), 
          "https://coraltraits.org/traits/#{tra.id}.zip"
        ]
      end
    end

    send_data csv_string, 
     :type => 'text/csv; charset=iso-8859-1; header=present', :stream => true,
     :disposition => "attachment; filename=ready_trait_#{Date.today.strftime('%Y%m%d')}.csv"
          
  end

  def export_ready_resources
    
    @observations = Observation.where(:id => Trait.where("release_status = ?", "ready_for_release").collect { |t| t.measurements.map(&:observation_id)})

    resources_string = CSV.generate do |csv|
      Resource.where(:id => @observations.map(&:resource).uniq).each do |res|
        csv << ["#{res.author}, #{res.title}. #{res.journal} #{res.volume_pages} (#{res.year}) DOI:#{res.doi_isbn}"]
      end
    end

    send_data resources_string, 
     :type => 'text/csv; charset=iso-8859-1; header=present', :stream => true,
     :disposition => "attachment; filename=ready_resources_#{Date.today.strftime('%Y%m%d')}.csv"
          
  end

  def export_ready
    
    @observations = Observation.where(:id => Trait.where("release_status = ?", "ready_for_release").collect { |t| t.measurements.map(&:observation_id)})

    send_zip(@observations)
              
  end

end
