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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190315012758) do

  create_table "delta_requests", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.bigint "delta_stream_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "duration", limit: 24
    t.datetime "start_time"
    t.datetime "end_time"
    t.boolean "not_parseable"
    t.string "number_returned"
    t.index ["delta_stream_id"], name: "index_delta_requests_on_delta_stream_id"
    t.index ["start_time"], name: "index_delta_requests_on_start_time"
  end

  create_table "delta_streams", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "frequency_minutes"
    t.integer "delta_reachback"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notams", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "transaction_id"
    t.string "scenario"
    t.boolean "xsi_nil_error"
    t.datetime "end_position"
    t.bigint "delta_request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delta_request_id"], name: "index_notams_on_delta_request_id"
  end

  add_foreign_key "delta_requests", "delta_streams"
  add_foreign_key "notams", "delta_requests"
end
