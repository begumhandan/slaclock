# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_15_170000) do
  create_table "comments", force: :cascade do |t|
    t.integer "ticket_id", null: false
    t.integer "author_id"
    t.text "body", null: false
    t.boolean "internal", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["ticket_id"], name: "index_comments_on_ticket_id"
  end

  create_table "holidays", force: :cascade do |t|
    t.date "date", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_holidays_on_date", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sla_pauses", force: :cascade do |t|
    t.integer "ticket_id", null: false
    t.datetime "started_at", null: false
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_id"], name: "index_sla_pauses_on_ticket_id"
  end

  create_table "tickets", force: :cascade do |t|
    t.string "subject", null: false
    t.text "body"
    t.string "requester_email", null: false
    t.integer "priority", default: 1, null: false
    t.integer "status", default: 0, null: false
    t.integer "assignee_id"
    t.datetime "first_response_due_at"
    t.datetime "first_responded_at"
    t.datetime "solved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "status_changed_at"
    t.index ["assignee_id"], name: "index_tickets_on_assignee_id"
    t.index ["status"], name: "index_tickets_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "comments", "tickets"
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "sla_pauses", "tickets"
  add_foreign_key "tickets", "users", column: "assignee_id"
end
