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

ActiveRecord::Schema[8.1].define(version: 2026_02_12_020810) do
  create_table "defect_codes", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_defect_codes_on_code", unique: true
  end

  create_table "defect_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "defect_code_id", null: false
    t.integer "defect_qty", default: 1
    t.text "description"
    t.integer "production_result_id", null: false
    t.datetime "updated_at", null: false
    t.index ["defect_code_id"], name: "index_defect_records_on_defect_code_id"
    t.index ["production_result_id"], name: "index_defect_records_on_production_result_id"
  end

  create_table "equipments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "equipment_code", null: false
    t.string "equipment_name", null: false
    t.boolean "is_active", default: true
    t.string "location"
    t.integer "manufacturing_process_id", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.index ["equipment_code"], name: "index_equipments_on_equipment_code", unique: true
    t.index ["manufacturing_process_id"], name: "index_equipments_on_manufacturing_process_id"
  end

  create_table "inspection_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "inspection_result_id", null: false
    t.string "item_name"
    t.integer "judgment"
    t.decimal "measured_value"
    t.string "spec_value"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["inspection_result_id"], name: "index_inspection_items_on_inspection_result_id"
  end

  create_table "inspection_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "insp_date"
    t.integer "insp_type"
    t.string "lot_no"
    t.integer "manufacturing_process_id", null: false
    t.text "notes"
    t.integer "result"
    t.datetime "updated_at", null: false
    t.integer "worker_id", null: false
    t.index ["manufacturing_process_id"], name: "index_inspection_results_on_manufacturing_process_id"
    t.index ["worker_id"], name: "index_inspection_results_on_worker_id"
  end

  create_table "manufacturing_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_active", default: true
    t.string "process_code", null: false
    t.string "process_name", null: false
    t.integer "process_order", null: false
    t.decimal "std_cycle_time", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["process_code"], name: "index_manufacturing_processes_on_process_code", unique: true
  end

  create_table "production_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "defect_qty", default: 0
    t.datetime "end_time"
    t.integer "equipment_id"
    t.integer "good_qty", default: 0
    t.string "lot_no", null: false
    t.integer "manufacturing_process_id", null: false
    t.datetime "start_time"
    t.datetime "updated_at", null: false
    t.integer "work_order_id", null: false
    t.integer "worker_id"
    t.index ["created_at"], name: "index_production_results_on_created_at"
    t.index ["equipment_id"], name: "index_production_results_on_equipment_id"
    t.index ["lot_no"], name: "index_production_results_on_lot_no", unique: true
    t.index ["manufacturing_process_id"], name: "index_production_results_on_manufacturing_process_id"
    t.index ["work_order_id"], name: "index_production_results_on_work_order_id"
    t.index ["worker_id"], name: "index_production_results_on_worker_id"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_active", default: true
    t.string "product_code", null: false
    t.integer "product_group", null: false
    t.string "product_name", null: false
    t.text "spec"
    t.string "unit", default: "EA"
    t.datetime "updated_at", null: false
    t.index ["product_code"], name: "index_products_on_product_code", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "work_orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "order_qty", null: false
    t.date "plan_date", null: false
    t.integer "priority", default: 5
    t.integer "product_id", null: false
    t.integer "status", default: 0
    t.datetime "updated_at", null: false
    t.string "work_order_code", null: false
    t.index ["plan_date"], name: "index_work_orders_on_plan_date"
    t.index ["product_id"], name: "index_work_orders_on_product_id"
    t.index ["status"], name: "index_work_orders_on_status"
    t.index ["work_order_code"], name: "index_work_orders_on_work_order_code", unique: true
  end

  create_table "workers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "employee_number", null: false
    t.boolean "is_active", default: true
    t.integer "manufacturing_process_id"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_number"], name: "index_workers_on_employee_number", unique: true
    t.index ["manufacturing_process_id"], name: "index_workers_on_manufacturing_process_id"
  end

  add_foreign_key "defect_records", "defect_codes"
  add_foreign_key "defect_records", "production_results"
  add_foreign_key "equipments", "manufacturing_processes"
  add_foreign_key "inspection_items", "inspection_results"
  add_foreign_key "inspection_results", "manufacturing_processes"
  add_foreign_key "inspection_results", "workers"
  add_foreign_key "production_results", "equipments"
  add_foreign_key "production_results", "manufacturing_processes"
  add_foreign_key "production_results", "work_orders"
  add_foreign_key "production_results", "workers"
  add_foreign_key "sessions", "users"
  add_foreign_key "work_orders", "products"
  add_foreign_key "workers", "manufacturing_processes"
end
