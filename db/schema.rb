# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120704094032) do

  create_table "abilities", :force => true do |t|
    t.integer  "character_id"
    t.string   "name"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "campaign_members", :force => true do |t|
    t.integer  "campaign_id"
    t.integer  "user_id"
    t.integer  "membership"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "campaigns", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "visibility",  :limit => 255
  end

  create_table "character_skills", :force => true do |t|
    t.integer  "character_id"
    t.string   "name"
    t.integer  "level"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.string   "required_skill"
    t.string   "synergy_name"
  end

  create_table "characters", :force => true do |t|
    t.string   "name"
    t.integer  "str"
    t.integer  "dex"
    t.integer  "int"
    t.integer  "fai"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "race"
    t.integer  "user_id"
    t.integer  "campaign_id"
    t.integer  "privacy"
  end

  create_table "equipment", :force => true do |t|
    t.integer  "character_id"
    t.string   "slot"
    t.string   "name"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "item_type"
  end

  create_table "skills", :force => true do |t|
    t.integer  "character_id"
    t.string   "name"
    t.integer  "level"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "required_skill_id"
  end

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "handle"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.string   "password_digest"
    t.integer  "active_character_id"
    t.integer  "character2_id"
    t.integer  "character3_id"
    t.integer  "active_campaign_id"
    t.integer  "campaign2_id"
    t.integer  "campaign3_id"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

end
