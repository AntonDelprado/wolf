class CharactersController < ApplicationController
	# helper ApplicationHelper
	before_filter :signed_in_user, except: [:show, :index, :export]
	before_filter :visible_to_user, only: [:show, :export]
	before_filter :correct_user, except: [:show, :index, :export, :new, :create]

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

	def stats
		@character = Character.find(params[:id])

		stats = @character.base_stats(params[:base_stats].to_i, params[:"raw_stats#{params[:base_stats]}"].to_i)
		@character.update_attributes(str: stats[0], dex: stats[1], int: stats[2], fai: stats[3])
		@character.update_base_skills
		if @character.save
			redirect_to @character, flash: { success: "Changed Stats" }
		else
			@character = Character.find(@character.id)
			redirect_to @character, flash: { error: "Failed to Change Stats" }
		end
	end

	def items
		@character = Character.find(params[:id])

		flash[:success] = "Changed Items to: Weapon:#{params[:primary]}, Off:#{params[:off_hand]}, Armour:#{params[:armour]}"
		equiped = @character.equip primary: params[:primary], off_hand: params[:off_hand], armour: params[:armour]
		redirect_to @character, flash: { success: "Equiped: #{equiped.join(', ')}" }
	end

	def skills
		@character = Character.find(params[:id])
		added,removed,changed = [],[],[]

		flash[:warn] = []

		params.each do |skill_name, value|
			if value == 'skill to remove'
				removed.concat @character.remove_skill(skill_name.sub('remove_','').gsub('_', ' '))
			elsif value == 'skill to add'
				added.concat @character.add_skill(skill_name.sub('add_','').gsub('_', ' '))
			elsif skill_name[0..5] == 'level_'
				changed.concat @character.set_skill_level(skill_name.sub('level_','').gsub('_',' '), value.to_i)
			end
		end

		messages = []
		if added.count > 1
			messages << "Added Skills: #{added.sort.join(', ')}"
		elsif added.count == 1
			messages << "Added Skill: #{added[0]}"
		end
		if removed.count > 1
			messages << "Removed Skills: #{removed.sort.join(', ')}"
		elsif removed.count == 1
			messages << "Removed Skill: #{removed[0]}"
		end
		messages << "Changed Skill Levels: #{changed.sort.join(', ')}" unless changed.empty?

		if messages.empty?
			redirect_to @character, flash: { warning: 'No Skills Changed' }
		else
			redirect_to @character, flash: { success: messages }
		end
	end

	def abilities
		@character = Character.find(params[:id])
		added, removed = [],[]

		params.each do |ability_name, value|
			if value == 'ability to add'
				add_name = ability_name.sub('add_','').gsub('_', ' ')
				added << add_name if @character.add_ability add_name
			elsif value == 'ability to remove'
				remove_name = ability_name.sub('remove_','').gsub('_', ' ')
				removed << remove_name if @character.remove_ability remove_name
			end
		end

		messages = []
		if added.count > 1
			messages << "Added Abilities: #{added.sort.join(', ')}"
		elsif added.count == 1
			messages << "Added Ability: #{added[0]}"
		end
		if removed.count > 1
			messages << "Removed Abilities: #{removed.sort.join(', ')}"
		elsif removed.count == 1
			messages << "Removed Ability: #{removed[0]}"
		end

		if messages.empty?
			redirect_to @character, flash: { warning: 'No Abilities Changed' }
		else
			redirect_to @character, flash: { success: messages }
		end
	end

	# Post to editing
	def update
		@character = Character.find(params[:id])

		if @character.update_attributes(params[:character])
			redirect_to @character, flash: { success: "Changed Character Attributes" }
		else
			flash.now[:error] = "Error: #{@character.errors.full_messages.join(', ')}"
			@character.reload
			render 'show'
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
