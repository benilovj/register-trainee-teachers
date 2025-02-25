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

ActiveRecord::Schema.define(version: 2022_07_26_160157) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "academic_cycles", force: :cascade do |t|
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index "tsrange((start_date)::timestamp without time zone, (end_date)::timestamp without time zone)", name: "academic_cycles_date_range", using: :gist
  end

  create_table "activities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "controller_name"
    t.string "action_name"
    t.jsonb "metadata"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_activities_on_user_id"
  end

  create_table "allocation_subjects", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "dttp_id"
    t.date "deprecated_on"
    t.index ["dttp_id"], name: "index_allocation_subjects_on_dttp_id", unique: true
    t.index ["name"], name: "index_allocation_subjects_on_name", unique: true
  end

  create_table "apply_application_sync_requests", force: :cascade do |t|
    t.integer "response_code"
    t.boolean "successful"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "recruitment_cycle_year"
    t.index ["recruitment_cycle_year"], name: "index_apply_application_sync_requests_on_recruitment_cycle_year"
  end

  create_table "apply_applications", force: :cascade do |t|
    t.integer "apply_id", null: false
    t.jsonb "application"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.jsonb "invalid_data"
    t.integer "state"
    t.string "accredited_body_code"
    t.integer "recruitment_cycle_year"
    t.index ["accredited_body_code"], name: "index_apply_applications_on_accredited_body_code"
    t.index ["apply_id"], name: "index_apply_applications_on_apply_id", unique: true
    t.index ["recruitment_cycle_year"], name: "index_apply_applications_on_recruitment_cycle_year"
  end

  create_table "audits", force: :cascade do |t|
    t.integer "auditable_id"
    t.string "auditable_type"
    t.integer "associated_id"
    t.string "associated_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "username"
    t.string "action"
    t.jsonb "audited_changes"
    t.integer "version", default: 0
    t.string "comment"
    t.string "remote_address"
    t.string "request_uuid"
    t.datetime "created_at"
    t.index ["associated_type", "associated_id"], name: "associated_index"
    t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
    t.index ["created_at"], name: "index_audits_on_created_at"
    t.index ["request_uuid"], name: "index_audits_on_request_uuid"
    t.index ["user_id", "user_type"], name: "user_index"
  end

  create_table "blazer_audits", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "query_id"
    t.text "statement"
    t.string "data_source"
    t.datetime "created_at"
    t.index ["query_id"], name: "index_blazer_audits_on_query_id"
    t.index ["user_id"], name: "index_blazer_audits_on_user_id"
  end

  create_table "blazer_checks", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "query_id"
    t.string "state"
    t.string "schedule"
    t.text "emails"
    t.text "slack_channels"
    t.string "check_type"
    t.text "message"
    t.datetime "last_run_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["creator_id"], name: "index_blazer_checks_on_creator_id"
    t.index ["query_id"], name: "index_blazer_checks_on_query_id"
  end

  create_table "blazer_dashboard_queries", force: :cascade do |t|
    t.bigint "dashboard_id"
    t.bigint "query_id"
    t.integer "position"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["dashboard_id"], name: "index_blazer_dashboard_queries_on_dashboard_id"
    t.index ["query_id"], name: "index_blazer_dashboard_queries_on_query_id"
  end

  create_table "blazer_dashboards", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["creator_id"], name: "index_blazer_dashboards_on_creator_id"
  end

  create_table "blazer_queries", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "name"
    t.text "description"
    t.text "statement"
    t.string "data_source"
    t.string "status"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["creator_id"], name: "index_blazer_queries_on_creator_id"
  end

  create_table "course_subjects", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.bigint "subject_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["course_id", "subject_id"], name: "index_course_subjects_on_course_id_and_subject_id", unique: true
    t.index ["course_id"], name: "index_course_subjects_on_course_id"
    t.index ["subject_id"], name: "index_course_subjects_on_subject_id"
  end

  create_table "courses", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "published_start_date", null: false
    t.integer "duration_in_years", null: false
    t.string "course_length"
    t.integer "qualification", null: false
    t.integer "route", null: false
    t.string "summary", null: false
    t.integer "level", null: false
    t.string "accredited_body_code", null: false
    t.integer "min_age"
    t.integer "max_age"
    t.integer "study_mode"
    t.uuid "uuid"
    t.integer "recruitment_cycle_year"
    t.date "full_time_start_date"
    t.date "full_time_end_date"
    t.date "part_time_start_date"
    t.date "part_time_end_date"
    t.index ["code", "accredited_body_code"], name: "index_courses_on_code_and_accredited_body_code"
    t.index ["recruitment_cycle_year"], name: "index_courses_on_recruitment_cycle_year"
    t.index ["uuid"], name: "index_courses_on_uuid", unique: true
  end

  create_table "data_migrations", primary_key: "version", id: :string, force: :cascade do |t|
  end

  create_table "degrees", force: :cascade do |t|
    t.integer "locale_code", null: false
    t.string "uk_degree"
    t.string "non_uk_degree"
    t.bigint "trainee_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "subject"
    t.string "institution"
    t.integer "graduation_year"
    t.string "grade"
    t.string "country"
    t.text "other_grade"
    t.string "slug", null: false
    t.uuid "dttp_id"
    t.uuid "institution_uuid"
    t.uuid "uk_degree_uuid"
    t.uuid "subject_uuid"
    t.uuid "grade_uuid"
    t.index ["dttp_id"], name: "index_degrees_on_dttp_id"
    t.index ["locale_code"], name: "index_degrees_on_locale_code"
    t.index ["slug"], name: "index_degrees_on_slug", unique: true
    t.index ["trainee_id"], name: "index_degrees_on_trainee_id"
  end

  create_table "disabilities", force: :cascade do |t|
    t.string "name", null: false
    t.string "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_disabilities_on_name", unique: true
  end

  create_table "dqt_trn_requests", force: :cascade do |t|
    t.bigint "trainee_id", null: false
    t.uuid "request_id", null: false
    t.jsonb "response"
    t.integer "state", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["request_id"], name: "index_dqt_trn_requests_on_request_id", unique: true
    t.index ["trainee_id"], name: "index_dqt_trn_requests_on_trainee_id"
  end

  create_table "dttp_accounts", force: :cascade do |t|
    t.uuid "dttp_id"
    t.string "ukprn"
    t.string "name"
    t.jsonb "response"
    t.datetime "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "urn"
    t.string "accreditation_id"
    t.index ["accreditation_id"], name: "index_dttp_accounts_on_accreditation_id"
    t.index ["dttp_id"], name: "index_dttp_accounts_on_dttp_id", unique: true
    t.index ["ukprn"], name: "index_dttp_accounts_on_ukprn"
    t.index ["urn"], name: "index_dttp_accounts_on_urn"
  end

  create_table "dttp_bursary_details", force: :cascade do |t|
    t.jsonb "response"
    t.uuid "dttp_id", null: false
    t.datetime "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["dttp_id"], name: "index_dttp_bursary_details_on_dttp_id", unique: true
  end

  create_table "dttp_degree_qualifications", force: :cascade do |t|
    t.jsonb "response"
    t.integer "state", default: 0
    t.uuid "dttp_id", null: false
    t.uuid "contact_dttp_id"
    t.datetime "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["dttp_id"], name: "index_dttp_degree_qualifications_on_dttp_id", unique: true
  end

  create_table "dttp_dormant_periods", force: :cascade do |t|
    t.jsonb "response"
    t.uuid "dttp_id", null: false
    t.uuid "placement_assignment_dttp_id"
    t.datetime "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["dttp_id"], name: "index_dttp_dormant_periods_on_dttp_id", unique: true
  end

  create_table "dttp_placement_assignments", force: :cascade do |t|
    t.jsonb "response"
    t.uuid "dttp_id", null: false
    t.uuid "contact_dttp_id"
    t.datetime "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "provider_dttp_id"
    t.uuid "academic_year"
    t.date "programme_start_date"
    t.date "programme_end_date"
    t.uuid "trainee_status"
    t.index ["dttp_id"], name: "index_dttp_placement_assignments_on_dttp_id", unique: true
  end

  create_table "dttp_providers", force: :cascade do |t|
    t.string "name"
    t.uuid "dttp_id"
    t.string "ukprn"
    t.datetime "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.jsonb "response"
    t.index ["dttp_id"], name: "index_dttp_providers_on_dttp_id", unique: true
  end

  create_table "dttp_schools", force: :cascade do |t|
    t.string "name"
    t.string "dttp_id"
    t.string "urn"
    t.datetime "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "status_code"
    t.index ["dttp_id"], name: "index_dttp_schools_on_dttp_id", unique: true
  end

  create_table "dttp_trainees", force: :cascade do |t|
    t.jsonb "response"
    t.integer "state", default: 0
    t.uuid "dttp_id", null: false
    t.uuid "provider_dttp_id"
    t.datetime "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.uuid "status"
    t.index ["dttp_id"], name: "index_dttp_trainees_on_dttp_id", unique: true
  end

  create_table "dttp_training_initiatives", force: :cascade do |t|
    t.jsonb "response"
    t.uuid "dttp_id", null: false
    t.datetime "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["dttp_id"], name: "index_dttp_training_initiatives_on_dttp_id", unique: true
  end

  create_table "dttp_users", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "dttp_id"
    t.string "provider_dttp_id"
    t.datetime "created_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", precision: 6, default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["dttp_id"], name: "index_dttp_users_on_dttp_id", unique: true
  end

  create_table "funding_method_subjects", force: :cascade do |t|
    t.bigint "funding_method_id"
    t.bigint "allocation_subject_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["allocation_subject_id", "funding_method_id"], name: "index_funding_methods_subjects_on_ids", unique: true
    t.index ["allocation_subject_id"], name: "index_funding_method_subjects_on_allocation_subject_id"
    t.index ["funding_method_id"], name: "index_funding_method_subjects_on_funding_method_id"
  end

  create_table "funding_methods", force: :cascade do |t|
    t.string "training_route", null: false
    t.integer "amount", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "funding_type"
    t.bigint "academic_cycle_id"
    t.index ["academic_cycle_id"], name: "index_funding_methods_on_academic_cycle_id"
  end

  create_table "funding_payment_schedule_row_amounts", force: :cascade do |t|
    t.integer "funding_payment_schedule_row_id"
    t.integer "month"
    t.integer "year"
    t.integer "amount_in_pence"
    t.boolean "predicted"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["funding_payment_schedule_row_id"], name: "index_payment_schedule_row_amounts_on_payment_schedule_row_id"
  end

  create_table "funding_payment_schedule_rows", force: :cascade do |t|
    t.integer "funding_payment_schedule_id"
    t.string "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["funding_payment_schedule_id"], name: "index_payment_schedule_rows_on_funding_payment_schedule_id"
  end

  create_table "funding_payment_schedules", force: :cascade do |t|
    t.integer "payable_id"
    t.string "payable_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["payable_id", "payable_type"], name: "index_funding_payment_schedules_on_payable_id_and_payable_type"
  end

  create_table "funding_trainee_summaries", force: :cascade do |t|
    t.integer "payable_id"
    t.string "payable_type"
    t.string "academic_year"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["payable_id", "payable_type"], name: "index_funding_trainee_summaries_on_payable_id_and_payable_type"
  end

  create_table "funding_trainee_summary_row_amounts", force: :cascade do |t|
    t.integer "funding_trainee_summary_row_id"
    t.integer "payment_type"
    t.integer "tier"
    t.integer "amount_in_pence"
    t.integer "number_of_trainees"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["funding_trainee_summary_row_id"], name: "index_trainee_summary_row_amounts_on_trainee_summary_row_id"
  end

  create_table "funding_trainee_summary_rows", force: :cascade do |t|
    t.integer "funding_trainee_summary_id"
    t.string "subject"
    t.string "route"
    t.string "lead_school_name"
    t.string "lead_school_urn"
    t.string "cohort_level"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["funding_trainee_summary_id"], name: "index_trainee_summary_rows_on_trainee_summary_id"
  end

  create_table "hesa_collection_requests", force: :cascade do |t|
    t.string "collection_reference"
    t.datetime "requested_at"
    t.text "response_body"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "state"
    t.index ["state"], name: "index_hesa_collection_requests_on_state"
  end

  create_table "hesa_metadata", force: :cascade do |t|
    t.bigint "trainee_id"
    t.integer "study_length"
    t.string "study_length_unit"
    t.string "itt_aim"
    t.string "itt_qualification_aim"
    t.string "fundability"
    t.string "service_leaver"
    t.string "course_programme_title"
    t.integer "placement_school_urn"
    t.date "pg_apprenticeship_start_date"
    t.string "year_of_course"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["trainee_id"], name: "index_hesa_metadata_on_trainee_id"
  end

  create_table "hesa_students", force: :cascade do |t|
    t.string "hesa_id"
    t.string "first_names"
    t.string "last_name"
    t.string "email"
    t.string "date_of_birth"
    t.string "ethnic_background"
    t.string "gender"
    t.string "ukprn"
    t.string "trainee_id"
    t.string "course_subject_one"
    t.string "course_subject_two"
    t.string "course_subject_three"
    t.string "itt_start_date"
    t.string "itt_end_date"
    t.string "employing_school_urn"
    t.string "lead_school_urn"
    t.string "mode"
    t.string "course_age_range"
    t.string "commencement_date"
    t.string "training_initiative"
    t.string "disability"
    t.string "end_date"
    t.string "reason_for_leaving"
    t.string "bursary_level"
    t.string "trn"
    t.string "training_route"
    t.string "nationality"
    t.string "hesa_updated_at"
    t.string "itt_aim"
    t.string "itt_qualification_aim"
    t.string "fund_code"
    t.string "study_length"
    t.string "study_length_unit"
    t.string "service_leaver"
    t.string "course_programme_title"
    t.string "pg_apprenticeship_start_date"
    t.string "year_of_course"
    t.json "degrees"
    t.json "placements"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "hesa_trn_requests", force: :cascade do |t|
    t.string "collection_reference"
    t.integer "state"
    t.text "response_body"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "hesa_trn_submissions", force: :cascade do |t|
    t.text "payload"
    t.datetime "submitted_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "lead_school_users", force: :cascade do |t|
    t.bigint "lead_school_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["lead_school_id"], name: "index_lead_school_users_on_lead_school_id"
    t.index ["user_id"], name: "index_lead_school_users_on_user_id"
  end

  create_table "nationalisations", force: :cascade do |t|
    t.bigint "trainee_id", null: false
    t.bigint "nationality_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["nationality_id"], name: "index_nationalisations_on_nationality_id"
    t.index ["trainee_id"], name: "index_nationalisations_on_trainee_id"
  end

  create_table "nationalities", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_nationalities_on_name", unique: true
  end

  create_table "provider_users", force: :cascade do |t|
    t.bigint "provider_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["provider_id", "user_id"], name: "index_provider_users_on_provider_id_and_user_id", unique: true
    t.index ["provider_id"], name: "index_provider_users_on_provider_id"
    t.index ["user_id"], name: "index_provider_users_on_user_id"
  end

  create_table "providers", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.uuid "dttp_id"
    t.boolean "apply_sync_enabled", default: false
    t.string "code"
    t.string "ukprn"
    t.string "accreditation_id"
    t.index ["accreditation_id"], name: "index_providers_on_accreditation_id", unique: true
    t.index ["dttp_id"], name: "index_providers_on_dttp_id", unique: true
  end

  create_table "schools", force: :cascade do |t|
    t.string "urn", null: false
    t.string "name", null: false
    t.string "postcode"
    t.string "town"
    t.date "open_date"
    t.date "close_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "lead_school", null: false
    t.tsvector "searchable"
    t.index ["close_date"], name: "index_schools_on_close_date", where: "(close_date IS NULL)"
    t.index ["lead_school"], name: "index_schools_on_lead_school", where: "(lead_school IS TRUE)"
    t.index ["searchable"], name: "index_schools_on_searchable", using: :gin
    t.index ["urn"], name: "index_schools_on_urn", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "subject_specialisms", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "allocation_subject_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "hecos_code"
    t.index "lower((name)::text)", name: "index_subject_specialisms_on_lower_name", unique: true
    t.index ["allocation_subject_id"], name: "index_subject_specialisms_on_allocation_subject_id"
  end

  create_table "subjects", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["code"], name: "index_subjects_on_code", unique: true
  end

  create_table "trainee_disabilities", force: :cascade do |t|
    t.bigint "trainee_id", null: false
    t.bigint "disability_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "additional_disability"
    t.index ["disability_id"], name: "index_trainee_disabilities_on_disability_id"
    t.index ["trainee_id"], name: "index_trainee_disabilities_on_trainee_id"
  end

  create_table "trainees", force: :cascade do |t|
    t.text "trainee_id"
    t.text "first_names"
    t.text "last_name"
    t.date "date_of_birth"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "address_line_one"
    t.text "address_line_two"
    t.text "town_city"
    t.text "postcode"
    t.text "email"
    t.uuid "dttp_id"
    t.text "middle_names"
    t.integer "training_route"
    t.text "international_address"
    t.integer "locale_code"
    t.integer "gender"
    t.integer "diversity_disclosure"
    t.integer "ethnic_group"
    t.text "ethnic_background"
    t.text "additional_ethnic_background"
    t.integer "disability_disclosure"
    t.text "course_subject_one"
    t.date "itt_start_date"
    t.jsonb "progress", default: {}
    t.bigint "provider_id", null: false
    t.date "outcome_date"
    t.date "itt_end_date"
    t.uuid "placement_assignment_dttp_id"
    t.string "trn"
    t.datetime "submitted_for_trn_at"
    t.integer "state", default: 0
    t.integer "withdraw_reason"
    t.datetime "withdraw_date"
    t.string "additional_withdraw_reason"
    t.date "defer_date"
    t.string "slug", null: false
    t.datetime "recommended_for_award_at"
    t.string "dttp_update_sha"
    t.date "commencement_date"
    t.date "reinstate_date"
    t.uuid "dormancy_dttp_id"
    t.bigint "lead_school_id"
    t.bigint "employing_school_id"
    t.bigint "apply_application_id"
    t.integer "course_min_age"
    t.integer "course_max_age"
    t.text "course_subject_two"
    t.text "course_subject_three"
    t.datetime "awarded_at"
    t.boolean "applying_for_bursary"
    t.integer "training_initiative"
    t.integer "bursary_tier"
    t.integer "study_mode"
    t.boolean "ebacc", default: false
    t.string "region"
    t.integer "course_education_phase"
    t.boolean "applying_for_scholarship"
    t.boolean "applying_for_grant"
    t.uuid "course_uuid"
    t.boolean "lead_school_not_applicable", default: false
    t.boolean "employing_school_not_applicable", default: false
    t.boolean "submission_ready", default: false
    t.integer "commencement_status"
    t.datetime "discarded_at"
    t.boolean "created_from_dttp", default: false, null: false
    t.string "hesa_id"
    t.jsonb "additional_dttp_data"
    t.boolean "created_from_hesa", default: false, null: false
    t.datetime "hesa_updated_at"
    t.bigint "course_allocation_subject_id"
    t.bigint "start_academic_cycle_id"
    t.bigint "end_academic_cycle_id"
    t.index ["apply_application_id"], name: "index_trainees_on_apply_application_id"
    t.index ["course_allocation_subject_id"], name: "index_trainees_on_course_allocation_subject_id"
    t.index ["course_uuid"], name: "index_trainees_on_course_uuid"
    t.index ["disability_disclosure"], name: "index_trainees_on_disability_disclosure"
    t.index ["discarded_at"], name: "index_trainees_on_discarded_at"
    t.index ["diversity_disclosure"], name: "index_trainees_on_diversity_disclosure"
    t.index ["dttp_id"], name: "index_trainees_on_dttp_id"
    t.index ["employing_school_id"], name: "index_trainees_on_employing_school_id"
    t.index ["end_academic_cycle_id"], name: "index_trainees_on_end_academic_cycle_id"
    t.index ["ethnic_group"], name: "index_trainees_on_ethnic_group"
    t.index ["gender"], name: "index_trainees_on_gender"
    t.index ["lead_school_id"], name: "index_trainees_on_lead_school_id"
    t.index ["locale_code"], name: "index_trainees_on_locale_code"
    t.index ["progress"], name: "index_trainees_on_progress", using: :gin
    t.index ["provider_id"], name: "index_trainees_on_provider_id"
    t.index ["slug"], name: "index_trainees_on_slug", unique: true
    t.index ["start_academic_cycle_id"], name: "index_trainees_on_start_academic_cycle_id"
    t.index ["state"], name: "index_trainees_on_state"
    t.index ["training_route"], name: "index_trainees_on_training_route"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "dfe_sign_in_uid"
    t.datetime "last_signed_in_at"
    t.uuid "dttp_id"
    t.boolean "system_admin", default: false
    t.datetime "welcome_email_sent_at"
    t.datetime "discarded_at"
    t.boolean "read_only", default: false
    t.index ["dfe_sign_in_uid"], name: "index_users_on_dfe_sign_in_uid", unique: true
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["dttp_id"], name: "index_unique_active_dttp_users", unique: true, where: "(discarded_at IS NULL)"
    t.index ["email"], name: "index_unique_active_users", unique: true, where: "(discarded_at IS NULL)"
  end

  create_table "validation_errors", force: :cascade do |t|
    t.bigint "user_id"
    t.string "form_object"
    t.jsonb "details"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_validation_errors_on_user_id"
  end

  add_foreign_key "activities", "users"
  add_foreign_key "course_subjects", "courses"
  add_foreign_key "course_subjects", "subjects"
  add_foreign_key "degrees", "trainees"
  add_foreign_key "dqt_trn_requests", "trainees"
  add_foreign_key "funding_methods", "academic_cycles"
  add_foreign_key "lead_school_users", "schools", column: "lead_school_id"
  add_foreign_key "lead_school_users", "users"
  add_foreign_key "nationalisations", "nationalities"
  add_foreign_key "nationalisations", "trainees"
  add_foreign_key "provider_users", "providers"
  add_foreign_key "provider_users", "users"
  add_foreign_key "subject_specialisms", "allocation_subjects"
  add_foreign_key "trainee_disabilities", "disabilities"
  add_foreign_key "trainee_disabilities", "trainees"
  add_foreign_key "trainees", "academic_cycles", column: "end_academic_cycle_id"
  add_foreign_key "trainees", "academic_cycles", column: "start_academic_cycle_id"
  add_foreign_key "trainees", "allocation_subjects", column: "course_allocation_subject_id"
  add_foreign_key "trainees", "apply_applications"
  add_foreign_key "trainees", "providers"
  add_foreign_key "trainees", "schools", column: "employing_school_id"
  add_foreign_key "trainees", "schools", column: "lead_school_id"
end
