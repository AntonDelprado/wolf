class CharactersController < ApplicationController
	# helper ApplicationHelper
	before_filter :signed_in_user, except: [:show, :index, :export]
	before_filter :visible_to_user, only: [:show, :export]
	before_filter :correct_user, only: [:edit, :update, :destroy]

	def new
		@character = Character.new
	end

	def create
		@character = Character.new(params[:character])
		if @character.campaign_id.nil?
			@character.privacy = :public
		else
			@character.privacy = :campaign
		end

		if @character.save
			current_user.push_active_character @character if signed_in?
			redirect_to @character, flash: { success: "Successfully Created #{@character.name}" }
		else
			render 'new'
		end
	end

	def show
		@character = Character.find(params[:id])
		current_user.push_active_character(@character) if signed_in?
	end

	def index
		@owned_characters = Character.find_all_by_user_id(current_user.id) if signed_in?
		@other_characters = Character.all.reject { |character| current_user_owns? character }
	end

	def export
		@character = Character.find(params[:id])
		send_data(@character.export_xml, type: 'text/xml', filename: "#{@character.name}.xml")
	end

	def import
		begin
			xml_doc = XML::Document.io(params[:character][:file])
		rescue #XML::Parser::ParseError
			redirect_to new_character_path, flash: { error: "Invalid XML File" }
			return
		end

		@character = Character.import_xml(xml_doc.root, current_user.id)

		if @character.nil?
			redirect_to new_character_path, flash: { error: "Invalid Character XML" }
		else
			redirect_to @character, flash: { success: "'#{@character.name}' sucessfully imported." }
		end
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
				redirect_to @character, flash: { success: "Changed Stats" }
			else
				@character = Character.find(@character.id)
				redirect_to @character, flash: { error: "Failed to Change Stats" }
			end

		elsif params[:change_items]
			flash[:success] = "Changed Items to: Weapon:#{params[:primary]}, Off:#{params[:off_hand]}, Armour:#{params[:armour]}"

			equiped = @character.equip primary: params[:primary], off_hand: params[:off_hand], armour: params[:armour]

			redirect_to @character, flash: { success: "Equiped: #{equiped.join(', ')}" }

		elsif params[:add_skill]
			added_skills = @character.add_skill params[:add_skill]
			if @character.save
				redirect_to @character, flash: { success: "Added: #{added_skills.join(', ')}" }
			else
				@character = Character.find(@character.id)
				redirect_to @character, flash: { error: "Failed to add: #{params[:add_skill]}" }
			end

		elsif params[:add_ability]
			@character.add_ability params[:add_ability]
			if @character.save
				redirect_to @character, flash: { success: "Added: #{params[:add_ability]}" }
			else
				@character = Character.find(@character.id)
				redirect_to @character, flash: { error: "Failed to add: #{params[:add_ability]}" }
			end

		elsif params[:remove_skills]
			removed = []
			params.each do |skill_name, param_value|
				removed.concat @character.remove_skill(skill_name) if param_value == "skill to remove"
			end

			if removed.empty?
				redirect_to @character, flash: { error: "Removing Skills Failed" }
			else
				redirect_to @character, flash: { success: "Removed: #{removed.join(', ')}" }
			end

		elsif params[:remove_abilities]
			removed = []
			params.each do |ability_name, param_value|
				if param_value == 'ability to remove'
					removed << ability_name unless @character.remove_ability(ability_name).nil?
				end
			end

			if @character.save and not removed.empty?
				redirect_to @character, flash: { success: "Removed: #{removed.join(', ')}" }
			else
				redirect_to @character, flash: { error: "Removing Abilities Failed" }
			end

		elsif params[:add_skills]
			added = []
			params.each do |skill_name, param_value|
				added.concat(@character.add_skill(skill_name)) if param_value == "skill to add"
			end

			if added.empty?
				redirect_to @character, flash: { error: "Adding Skills Failed" }
			else
				redirect_to @character, flash: { success: "Added: #{added.join(', ')}" }
			end

		elsif params[:add_abilities]
			added = []
			params.each do |ability_name, param_value|
				if param_value == "ability to add"
					added << ability_name unless @character.add_ability(ability_name).nil?
				end
			end

			if @character.save and not added.empty?
				redirect_to @character, flash: { success: "Added: #{added.join(', ')}"}
			else
				redirect_to @character, flash: { error: "Adding Abilities Failed" }
			end

		elsif params[:skill_level]
			changed = []
			params.each do |key, value|
				if key.class == String && key[0,5] == "level"
					skill_name = key.sub('level_', '').gsub('_', ' ')
					changed.concat @character.set_skill_level(skill_name, value.to_i)
				end
			end

			redirect_to @character, flash: { success: "Changed Levels: #{changed.uniq.join(', ')}" }

		else
			if @character.update_attributes(params[:character])
				redirect_to @character, flash: { success: "Changed Character Attributes" }
			else
				flash.now[:error] = "Error: #{@character.errors.full_messages.join(', ')}"
				@character.reload
				render 'show'
			end

		end
	end

	def destroy
		character = Character.find(params[:id])
		character.destroy
		redirect_to characters_path, flash: { success: "Successfully Destroyed: #{character.name}" }
	end

	private

	def signed_in_user
		redirect_to signin_path, notice: 'To do this action you must sign in' unless signed_in?
	end

	def visible_to_user
		@character = Character.find(params[:id])
		redirect_to characters_path, flash: { error: "Unable to access character" } unless visible? @character
	end

	def correct_user
		@character = Character.find(params[:id])
		redirect_to characters_path, flash: { error: "You do not own that Character" } unless current_user_owns? @character
	end
end
