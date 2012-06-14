class CharactersController < ApplicationController
	helper ApplicationHelper

	def new
		@character = Character.new
	end

	def create
		@character = Character.new(params[:character])
		if @character.save
			flash[:success] = "Successfully Created #{@character.name}"
			session[:character] = @character
			redirect_to @character
		else
			render 'new'
		end
	end

	def show
		@character = Character.find(params[:id])
		session[:character] = @character
	end

	def index
	end

	# Prior to editing
	def edit
		@character = Character.find(params[:id])
	end

	# Post to editing
	def update
		@character = Character.find(params[:id])

		if params[:base_stats]
			stats = @character.base_stats(params[:base_stats].to_i, params[:"raw_stats#{params[:base_stats]}"].to_i)
			@character.update_attributes(str: stats[0], dex: stats[1], int: stats[2], fai: stats[3])
			@character.update_base_skills
			if @character.save
				flash[:success] = "Changed Stats"
			else
				flash[:error] = "Failed to Change Stats"
				@character = Character.find(@character.id)
			end
			redirect_to @character

		elsif params[:add_skill]
			added_skills = @character.add_skill params[:add_skill]
			if @character.save
				flash[:success] = "Added: #{added_skills.join(', ')}"
			else
				flash[:error] = "Failed to add: #{params[:add_skill]}"
				@character = Character.find(@character.id)
			end
			redirect_to @character

		elsif params[:add_ability]
			@character.add_ability params[:add_ability]
			if @character.save
				flash[:success] = "Added: #{params[:add_ability]}"
			else
				flash[:error] = "Failed to add: #{params[:add_ability]}"
				@character = Character.find(@character.id)
			end
			redirect_to @character

		elsif params[:remove_skills]
			flash[:success] = "Removed: "
			params.each do |skill_name, param_value|
				if param_value == "skill to remove"
					flash[:success] << "#{skill_name}, "
					@character.remove_skill skill_name
				end
			end
			if !@character.save
				flash[:success] = nil
				flash[:error] = "Removing Skills Failed"
			end
			redirect_to @character

		elsif params[:remove_abilities]
			flash[:success] = "Removed: "
			params.each do |ability_name, param_value|
				if param_value == 'ability to remove'
					flash[:success] << "#{ability_name}, "
					@character.remove_ability ability_name
				end
			end
			if !@character.save
				flash[:success] = nil
				flash[:error] = "Removing Abilities Failed"
			end
			redirect_to @character

		elsif params[:add_skills]
			flash[:success] = "Added: "
			params.each do |skill_name, param_value|
				if param_value == "skill to add"
					flash[:success] << "#{skill_name}, "
					@character.add_skill skill_name
				end
			end
			if !@character.save
				flash[:success] = nil
				flash[:error] = "Adding Skills Failed"
			end
			redirect_to @character

		elsif params[:add_abilities]
			flash[:success] = "Added: "
			params.each do |ability_name, param_value|
				if param_value == "ability to add"
					flash[:success] << "#{ability_name}, "
					@character.add_ability ability_name
				end
			end
			if !@character.save
				flash[:success] = nil
				flash[:error] = "Adding Abilities Failed"
			end
			redirect_to @character

		elsif params[:skill_level]
			flash[:success] = "Changed Levels: #{params.inspect}"
			changed = []
			params.each do |key, value|
				if key.class == String && key[0,5] == "level"
					skill_name = key[6..100].sub('_', ' ')
					if @character.skills[skill_name] != value.to_i
						changed << skill_name
						@character.skills[skill_name] = value.to_i
					end
				end
			end
			@character.save
			flash[:success] = "Changed Levels: #{changed.join(', ')}"
			redirect_to @character

		elsif @character.update_attributes(params[:character])
			redirect_to @character
		else
			flash.now[:error] = "Error: #{@character.errors.full_messages.join(', ')}"
			@character = Character.find(params[:id]) # undo the damage
			render 'show'
		end
	end

	def destroy
		character = Character.find(params[:id])
		flash[:success] = "Successfully destroyed: #{character.name}"
		character.destroy
		redirect_to characters_path
	end
end
