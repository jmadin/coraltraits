class SearchController < ApplicationController
	def index
		
		if params[:search] && params[:search] != ""
			if not params[:model_name]
				params[:model_name] = ['Location', 'Coral', 'Trait', 'Resource', 'Standard', 'Observation']
			end
			@result_present = false
			params[:model_name].each do |m|
				@model = m.classify.constantize
				name = m.downcase + '_search'
				puts "name: "
				puts name
				
				search_result = @model.search do
					fulltext params[:search]
					paginate :page => 1, :per_page => 100
				end

				if not search_result.results.blank?
					@result_present = true
				end
				
				instance_variable_set("@#{name}", search_result)
			end
		else
			@location_search = nil
		end
	end

	def json_completion

		search = Coral.search do 
			keywords(params["search"])
		end

		bucket = []
		bucket << search.results.map{ |x| x.coral_name}
		render :json => bucket.flatten
	end
end
