# frozen_string_literal: true

FactoryBot.define do
  factory :abstract_trainee, class: "Trainee" do
    transient do
      randomise_subjects { false }
      potential_itt_start_date { itt_start_date || Faker::Date.in_date_period(month: 9, year: current_recruitment_cycle_year) }
    end

    sequence :trainee_id do |n|
      year = potential_itt_start_date.strftime("%y").to_i
      "#{year}/#{year + 1}-#{n}"
    end

    provider

    training_route { TRAINING_ROUTE_ENUMS[:assessment_only] }

    first_names { Faker::Name.first_name }
    middle_names { Faker::Name.middle_name }
    last_name { Faker::Name.last_name }
    gender { Trainee.genders.keys.sample }
    slug { SecureRandom.base58(Sluggable::SLUG_LENGTH) }

    diversity_disclosure { Diversities::DIVERSITY_DISCLOSURE_ENUMS[:diversity_not_disclosed] }
    ethnic_group { nil }
    ethnic_background { nil }
    additional_ethnic_background { nil }
    disability_disclosure { nil }

    start_academic_cycle { AcademicCycle.for_date(itt_start_date) }
    end_academic_cycle { AcademicCycle.for_date(itt_end_date) }

    with_uk_address
    email { "#{first_names}.#{last_name}@example.com" }
    applying_for_bursary { nil }

    factory :trainee do
      date_of_birth { Faker::Date.birthday(min_age: 18, max_age: 65) }
    end

    factory :trainee_for_form do
      transient do
        form_dob { Faker::Date.birthday(min_age: 18, max_age: 65) }
      end
      add_attribute("date_of_birth(3i)") { form_dob.day.to_s }
      add_attribute("date_of_birth(2i)") { form_dob.month.to_s }
      add_attribute("date_of_birth(1i)") { form_dob.year.to_s }
    end

    trait :with_uk_address do
      address_line_one { Faker::Address.street_address }
      address_line_two { Faker::Address.street_name }
      town_city { Faker::Address.city }
      postcode { Faker::Address.postcode }
      international_address { nil }
      locale_code { :uk }
    end

    trait :with_non_uk_address do
      address_line_one { nil }
      address_line_two { nil }
      town_city { nil }
      postcode { nil }
      international_address { Faker::Address.full_address }
      locale_code { :non_uk }
    end

    trait :incomplete do
      trainee_id { nil }
      first_names { nil }
      middle_names { nil }
      last_name { nil }
      gender { nil }
      date_of_birth { nil }

      diversity_disclosure { nil }
      ethnic_group { nil }
      ethnic_background { nil }
      additional_ethnic_background { nil }
      disability_disclosure { nil }

      address_line_one { nil }
      address_line_two { nil }
      town_city { nil }
      postcode { nil }
      international_address { nil }
      locale_code { nil }
      email { nil }
      commencement_date { nil }
    end

    trait :in_progress do
      with_secondary_course_details
      with_start_date
      with_degree
      with_funding
    end

    trait :with_degree do
      degrees { [build(:degree, :uk_degree_with_details)] }
    end

    trait :submission_ready do
      submission_ready { true }
    end

    trait :not_submission_ready do
      submission_ready { false }
    end

    trait :completed do
      in_progress
      training_initiative { ROUTE_INITIATIVES_ENUMS.keys.sample }
      applying_for_bursary { false }
      applying_for_scholarship { false }
      applying_for_grant { false }
      nationalities { [Nationality.all.sample || build(:nationality)] }
      progress do
        Progress.new(
          personal_details: true,
          contact_details: true,
          diversity: true,
          degrees: true,
          course_details: true,
          training_details: true,
          placement_details: true,
          schools: true,
          funding: true,
          trainee_data: true,
        )
      end
      submission_ready
    end

    trait :submitted_with_start_date do
      submitted_for_trn
      with_start_date
    end

    trait :with_subject_specialism do
      transient do
        subject_name { nil }
      end

      course_subject_one { create(:subject_specialism, subject_name: subject_name).name }
    end

    trait :with_primary_education do
      course_education_phase { COURSE_EDUCATION_PHASE_ENUMS[:primary] }
    end

    trait :with_secondary_education do
      course_education_phase { COURSE_EDUCATION_PHASE_ENUMS[:secondary] }
    end

    trait :with_primary_course_details do
      transient do
        primary_specialism_subjects { PUBLISH_PRIMARY_SUBJECT_SPECIALISM_MAPPING.values.sample }
      end
      with_primary_education
      course_subject_one { primary_specialism_subjects.first }
      course_subject_two { primary_specialism_subjects.second }
      course_subject_three { primary_specialism_subjects.third }
      course_age_range do
        Dttp::CodeSets::AgeRanges::MAPPING.select do |_, v|
          v[:option] == :main && v[:levels]&.include?(course_education_phase.to_sym)
        end.keys.sample
      end
      with_study_mode_and_course_dates
      course_allocation_subject { create(:subject_specialism, name: course_subject_one)&.allocation_subject }
    end

    trait :with_secondary_course_details do
      with_secondary_education
      course_subject_one do
        if randomise_subjects
          Dttp::CodeSets::CourseSubjects::MAPPING.keys.reject { |subject| SubjectSpecialism::PRIMARY_SUBJECT_NAMES.include?(subject) }.sample
        else
          ::CourseSubjects::MATHEMATICS
        end
      end
      course_subject_two { nil }
      course_subject_three { nil }
      course_age_range do
        Dttp::CodeSets::AgeRanges::MAPPING.select do |_, v|
          v[:option] == :main && v[:levels]&.include?(course_education_phase.to_sym)
        end.keys.sample
      end
      with_study_mode_and_course_dates
      with_course_allocation_subject
    end

    trait :with_course_allocation_subject do
      course_allocation_subject { SubjectSpecialism.find_by(name: course_subject_one)&.allocation_subject }
    end

    trait :with_study_mode_and_course_dates do
      study_mode { TRAINEE_STUDY_MODE_ENUMS.keys.sample }
      itt_start_date { Faker::Date.in_date_period(month: 9, year: current_recruitment_cycle_year) }
      itt_end_date do
        additional_years = if [2, 9, 10].include?(training_route)
                             3
                           elsif study_mode == "part_time"
                             2
                           else
                             1
                           end
        Faker::Date.in_date_period(month: 6, year: current_recruitment_cycle_year + additional_years)
      end
    end

    trait :with_study_mode_and_future_course_dates do
      study_mode { TRAINEE_STUDY_MODE_ENUMS.keys.sample }
      itt_start_date { Faker::Date.in_date_period(month: 9, year: current_recruitment_cycle_year + 1) }
      itt_end_date do
        additional_years = if [2, 9, 10].include?(training_route)
                             3
                           elsif study_mode == "part_time"
                             2
                           else
                             1
                           end
        Faker::Date.in_date_period(month: 6, year: itt_start_date.year + additional_years)
      end
    end

    trait :with_publish_course_details do
      training_route { TRAINING_ROUTES_FOR_COURSE.keys.sample }
      course_uuid { create(:course_with_subjects, route: training_route, accredited_body_code: provider.code).uuid }
      with_secondary_course_details
    end

    trait :with_start_date do
      commencement_date do
        if itt_start_date.present?
          Faker::Date.between(from: itt_start_date, to: itt_start_date + rand(20).days)
        else
          Time.zone.today
        end
      end
    end

    trait :itt_start_date_in_the_past do
      with_study_mode_and_course_dates
    end

    trait :itt_start_date_in_the_future do
      with_study_mode_and_future_course_dates
    end

    trait :diversity_disclosed do
      diversity_disclosure { Diversities::DIVERSITY_DISCLOSURE_ENUMS[:diversity_disclosed] }
    end

    trait :diversity_not_disclosed do
      diversity_disclosure { Diversities::DIVERSITY_DISCLOSURE_ENUMS[:diversity_not_disclosed] }
    end

    trait :disability_not_provided do
      disability_disclosure { Diversities::DISABILITY_DISCLOSURE_ENUMS[:not_provided] }
    end

    trait :with_ethnic_group do
      ethnic_group { (Diversities::ETHNIC_GROUP_ENUMS.values - ["not_provided_ethnic_group"]).sample }
    end

    trait :with_ethnic_background do
      ethnic_background { Dttp::CodeSets::Ethnicities::MAPPING.keys.sample }
    end

    trait :disabled do
      disability_disclosure { Diversities::DISABILITY_DISCLOSURE_ENUMS[:disabled] }
    end

    trait :disabled_with_disabilites_disclosed do
      disabled
      transient do
        disabilities_count { 1 }
      end

      after(:create) do |trainee, evaluator|
        create_list(:trainee_disability, evaluator.disabilities_count, trainee: trainee)
      end
    end

    trait :with_diversity_information do
      diversity_disclosed
      with_ethnic_group
      with_ethnic_background
      disabled_with_disabilites_disclosed
    end

    trait :with_placement_assignment do
      placement_assignment_dttp_id { SecureRandom.uuid }
    end

    trait :with_outcome_date do
      outcome_date { Faker::Date.in_date_period }
    end

    trait :provider_led_postgrad do
      training_route { TRAINING_ROUTE_ENUMS[:provider_led_postgrad] }
      study_mode { COURSE_STUDY_MODES[:full_time] }
    end

    trait :with_early_years_course_details do
      course_subject_one { CourseSubjects::EARLY_YEARS_TEACHING }
      course_age_range { AgeRange::ZERO_TO_FIVE }
      with_study_mode_and_course_dates
      course_education_phase { COURSE_EDUCATION_PHASE_ENUMS[:early_years] }
    end

    trait :early_years_assessment_only do
      training_route { TRAINING_ROUTE_ENUMS[:early_years_assessment_only] }
      with_early_years_course_details
    end

    trait :early_years_salaried do
      training_route { TRAINING_ROUTE_ENUMS[:early_years_salaried] }
      with_early_years_course_details
    end

    trait :early_years_postgrad do
      training_route { TRAINING_ROUTE_ENUMS[:early_years_postgrad] }
      with_early_years_course_details
    end

    trait :early_years_undergrad do
      training_route { TRAINING_ROUTE_ENUMS[:early_years_undergrad] }
      with_early_years_course_details
    end

    trait :school_direct_tuition_fee do
      training_route { TRAINING_ROUTE_ENUMS[:school_direct_tuition_fee] }
      study_mode { COURSE_STUDY_MODES[:full_time] }
    end

    trait :school_direct_salaried do
      training_route { TRAINING_ROUTE_ENUMS[:school_direct_salaried] }
      study_mode { COURSE_STUDY_MODES[:full_time] }
    end

    trait :opt_in_undergrad do
      training_route { TRAINING_ROUTE_ENUMS[:opt_in_undergrad] }
    end

    trait :draft do
      completed
      state { "draft" }
      submission_ready
    end

    trait :incomplete_draft do
      state { "draft" }
    end

    trait :submitted_for_trn do
      completed
      dttp_id { SecureRandom.uuid }
      submitted_for_trn_at { Time.zone.now }
      state { "submitted_for_trn" }
      submission_ready
    end

    trait :trn_received do
      submitted_for_trn
      trn { Faker::Number.number(digits: 7) }
      state { "trn_received" }
    end

    trait :recommended_for_award do
      trn_received
      outcome_date { Time.zone.now }
      recommended_for_award_at { Time.zone.now }
      state { "recommended_for_award" }
    end

    trait :with_withdrawal_date do
      withdraw_date { Faker::Date.between(from: potential_itt_start_date, to: potential_itt_start_date + 1.year) }
    end

    trait :withdrawn do
      trn_received
      with_withdrawal_date
      state { "withdrawn" }
    end

    trait :deferred do
      trn_received
      defer_date { potential_itt_start_date }
      state { "deferred" }
    end

    trait :reinstated do
      completed
      defer_date { potential_itt_start_date }
      reinstate_date { Faker::Date.in_date_period }
      state { "trn_received" }
    end

    trait :awarded do
      recommended_for_award
      state { "awarded" }
      awarded_at { Time.zone.now }
    end

    trait :eyts_awarded do
      training_route { EARLY_YEARS_TRAINING_ROUTES.keys.sample }
      state { "awarded" }
    end

    trait :eyts_recommended do
      training_route { EARLY_YEARS_TRAINING_ROUTES.keys.sample }
      state { "recommended_for_award" }
    end

    trait :qts_awarded do
      training_route { "school_direct_salaried" }
      state { "awarded" }
    end

    trait :qts_recommended do
      training_route { "school_direct_salaried" }
      state { "recommended_for_award" }
    end

    trait :with_dttp_dormancy do
      deferred
      dormancy_dttp_id { SecureRandom.uuid }
    end

    trait :withdrawn_for_specific_reason do
      with_withdrawal_date
      withdraw_reason { WithdrawalReasons::SPECIFIC.sample }
    end

    trait :withdrawn_for_another_reason do
      with_withdrawal_date
      withdraw_reason { WithdrawalReasons::FOR_ANOTHER_REASON }
      additional_withdraw_reason { Faker::Lorem.paragraph }
    end

    trait :with_related_courses do
      training_route { TRAINING_ROUTES_FOR_COURSE.keys.sample }

      transient do
        courses_count { 5 }
        subject_names { [] }
        study_mode { "full_time" }
        recruitment_cycle_year { Settings.current_default_course_year }
      end

      after(:create) do |trainee, evaluator|
        create_list(:course_with_subjects, evaluator.courses_count,
                    subject_names: evaluator.subject_names,
                    accredited_body_code: trainee.provider.code,
                    route: trainee.training_route,
                    study_mode: evaluator.study_mode,
                    recruitment_cycle_year: evaluator.recruitment_cycle_year)

        trainee.reload
      end
    end

    trait :with_lead_school do
      association :lead_school, factory: %i[school lead]
    end

    trait :with_employing_school do
      association :employing_school, factory: :school
    end

    trait :with_apply_application do
      apply_application
    end

    trait :with_dttp_trainee do
      dttp_trainee
    end

    trait :with_invalid_apply_application do
      degrees { [build(:degree, :uk_degree_with_details, institution: "Unknown institution")] }
      apply_application { build(:apply_application, :with_invalid_data, degree_slug: degrees.first.slug) }
    end

    trait :with_funding do
      training_initiative { ROUTE_INITIATIVES_ENUMS.keys.sample }
      applying_for_bursary { Faker::Boolean.boolean }
    end

    trait :with_provider_led_bursary do
      transient do
        funding_amount { 100 }
      end

      applying_for_bursary { true }

      after(:create) do |trainee, evaluator|
        funding_method = create(:funding_method, :bursary, :with_subjects, training_route: :provider_led_postgrad)
        funding_method.amount = evaluator.funding_amount if evaluator.funding_amount.present?
        funding_method.save

        trainee.course_allocation_subject = funding_method.allocation_subjects.first
        trainee.training_route = funding_method.training_route
        trainee.commencement_date = funding_method.academic_cycle.start_date
      end
    end

    trait :with_early_years_grant do
      applying_for_grant { true }

      after(:create) do |trainee, _|
        funding_method = create(:funding_method, :grant, :with_subjects, training_route: :early_years_salaried)
        trainee.course_allocation_subject = funding_method.allocation_subjects.first
        trainee.training_route = funding_method.training_route
        trainee.commencement_date = funding_method.academic_cycle.start_date
      end
    end

    trait :with_scholarship do
      applying_for_scholarship { true }

      after(:create) do |trainee, _|
        funding_method = create(:funding_method, :scholarship, :with_subjects, training_route: :provider_led_postgrad)
        trainee.course_allocation_subject = funding_method.allocation_subjects.first
        trainee.training_route = funding_method.training_route
        trainee.commencement_date = funding_method.academic_cycle.start_date
      end
    end

    trait :with_grant do
      transient do
        funding_amount { 100 }
      end

      applying_for_grant { true }

      after(:create) do |trainee, evaluator|
        funding_method = create(:funding_method, :grant, :with_subjects, training_route: :provider_led_postgrad)
        funding_method.amount = evaluator.funding_amount if evaluator.funding_amount.present?
        funding_method.save

        trainee.course_allocation_subject = funding_method.allocation_subjects.first
        trainee.training_route = funding_method.training_route
        trainee.commencement_date = funding_method.academic_cycle.start_date
      end
    end

    trait :with_tiered_bursary do
      applying_for_bursary { true }
      bursary_tier { BURSARY_TIER_ENUMS[:tier_one] }
    end

    trait :with_hpitt_provider do
      training_route { TRAINING_ROUTE_ENUMS[:hpitt_postgrad] }
      region { Dttp::CodeSets::Regions::MAPPING.keys.sample }
      association :provider, factory: %i[provider teach_first]
    end

    trait :discarded do
      discarded_at { Time.zone.now }
    end

    trait :created_from_dttp do
      created_from_dttp { true }
    end

    trait :imported_from_hesa do
      hesa_id { Faker::Number.number(digits: 13) }
      created_from_hesa { true }
      hesa_updated_at { Faker::Time.between(from: 1.month.ago, to: Time.zone.now) }
      hesa_student { create(:hesa_student, hesa_id: hesa_id) }
    end
  end
end
