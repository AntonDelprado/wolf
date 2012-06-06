class CharactersController < ApplicationController
	def new
		@character = Character.new
	end

	def create
		@character = Character.new(params[:character])
		case @character.race
		when 'Wolf', 'Dwarf'
			@character.str = 12
			@character.dex = 4
			@character.int = 4
			@character.fai = 4
		when 'Goblin'
			@character.str = 8
			@character.dex = 6
			@character.int = 4
			@character.fai = 4
		when 'Vampire'
			@character.str = 12
			@character.dex = 12
			@character.int = 12
			@character.fai = 4
		end
		@character.skills = {}
		@character.abilities = []
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
