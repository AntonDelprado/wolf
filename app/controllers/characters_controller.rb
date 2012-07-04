class CharactersController < ApplicationController
	include ActionView::Helpers::TextHelper
	# helper ApplicationHelper
	before_filter :signed_in_user, except: [:show, :index, :export]
	before_filter :visible_to_user, only: [:show, :export]
	before_filter :correct_user, except: [:show, :index, :export, :new, :create, :import]

	def new
		@character = Character.new
	end

	def create
		@character = current_user.characters.build params[:character]
		@character.privacy ||= :campaign if @character.in_campaign?
		@character.privacy ||= :public

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
		if signed_in?
			campaign_ids = current_user.campaigns.collect { |campaign| campaign.id }

			owned = Character.where(user_id: current_user.id)
			campaign = Character.where('user_id <> ? AND campaign_id IN (?) AND privacy IN (?)',
				current_user.id, campaign_ids, [Character.privacy(:public), Character.privacy(:campaign)]).order('campaign_id, name')
			other = Character.where('user_id <> ? AND (campaign_id NOT IN (?) OR campaign_id IS NULL) AND privacy = ?',
				current_user.id, campaign_ids, Character.privacy(:public)).order('name')
		else
			other = Character.where('privacy = ?', Character.privacy(:public)).order('name')
		end

		@owned_characters = owned.paginate(page: params[:owned_page], per_page: 12) if owned
		@campaign_characters = campaign.paginate(page: params[:campaign_page], per_page: 12) if campaign
		@other_characters = other.paginate(page: params[:other_page], per_page: 12)

		if campaign
			@campaigns = {}
			@campaign_characters.each do |character|
				(@campaigns[character.campaign_id] ||= []) << character
			end
		end
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
		if @character.update_attributes(str: stats[0], dex: stats[1], int: stats[2], fai: stats[3])
			@character.update_base_skills
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

		changed = []
		starting_skills = @character.skills.collect { |skill| skill.name }

		params.each do |skill_name, value|
			if value == 'skill to remove'
				@character.remove_skill(skill_name.sub('remove_','').gsub('_', ' '))
			elsif value == 'skill to add'
				@character.add_skill(skill_name.sub('add_','').gsub('_', ' '))
			elsif skill_name[0..5] == 'level_'
				changed.concat @character.skill(skill_name.sub('level_','').gsub('_',' ')).set_level(value.to_i)
			end
		end

		ending_skills = @character.skills(true).collect { |skill| skill.name }

		added = ending_skills - starting_skills
		removed = starting_skills - ending_skills
		changed.uniq!

		messages = []
		messages << "Added #{pluralize(added.count, 'Skill')}: #{added.sort.join(', ')}" unless added.empty?
		messages << "Removed #{pluralize(removed.count, 'Skill')}: #{removed.sort.join(', ')}" unless removed.empty?
		messages << "Changed #{pluralize(changed.count, 'Skill Level')}: #{changed.sort.join(', ')}" unless changed.empty?

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

		added.uniq!
		removed.uniq!

		messages = []
		messages << "Added #{pluralize(added.count, 'Ability')}: #{added.sort.join(', ')}" unless added.empty?
		messages << "Removed #{pluralize(removed.count, 'Ability')}: #{removed.sort.join(', ')}" unless removed.empty?

		if messages.empty?
			redirect_to @character, flash: { warning: 'No Abilities Changed' }
		else
			redirect_to @character, flash: { success: messages }
		end
	end

	# Post to editing
	def update
		@character = Character.find(params[:id])

		raise "Params: #{params.inspect}"

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
