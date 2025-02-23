# frozen_string_literal: true

require "rails_helper"

module Trainees
  describe CreateFromHesa do
    let(:nationality_name) { ApplyApi::CodeSets::Nationalities::MAPPING[student_attributes[:nationality]] }
    let(:hesa_api_stub) { ApiStubs::HesaApi.new(hesa_stub_attributes) }
    let(:student_node) { hesa_api_stub.student_node }
    let(:student_attributes) { hesa_api_stub.student_attributes }
    let(:create_custom_state) { "implemented where necessary" }
    let(:hesa_stub_attributes) { { trn: hesa_trn } }
    let(:hesa_trn) { Faker::Number.number(digits: 7).to_s }
    let(:trainee_degree) { trainee.degrees.first }
    let(:hesa_course_subject_codes) { Hesa::CodeSets::CourseSubjects::MAPPING.invert }
    let(:hesa_age_range_codes) { Hesa::CodeSets::AgeRanges::MAPPING.invert }
    let!(:start_academic_cycle) { create(:academic_cycle, cycle_year: 2016) }
    let!(:end_academic_cycle) { create(:academic_cycle, cycle_year: 2018) }
    let!(:after_next_academic_cycle) { create(:academic_cycle, one_after_next_cycle: true) }

    let!(:course_allocation_subject) do
      create(:subject_specialism, name: CourseSubjects::BIOLOGY).allocation_subject
    end

    subject(:trainee) { Trainee.first }

    before do
      allow(Dqt::RegisterForTrnJob).to receive(:perform_later)
      allow(Sentry).to receive(:capture_message)
      create(:nationality, name: nationality_name)
      create(:provider, ukprn: student_attributes[:ukprn])
      create(:school, urn: student_attributes[:lead_school_urn])
      create_custom_state
      described_class.call(student_node: student_node)
    end

    describe "HESA information imported from XML" do
      it "updates the Trainee ID, HESA ID and TRN" do
        expect(trainee.trainee_id).to eq(student_attributes[:trainee_id])
        expect(trainee.hesa_id).to eq(student_attributes[:hesa_id])
        expect(trainee.trn).to eq(student_attributes[:trn])
        expect(trainee.course_allocation_subject).to eq(course_allocation_subject)
      end

      it "updates the trainee's personal details" do
        expect(trainee.first_names).to eq(student_attributes[:first_names])
        expect(trainee.last_name).to eq(student_attributes[:last_name])
        expect(trainee.gender).to eq("male")
        expect(trainee.date_of_birth).to eq(Date.parse(student_attributes[:date_of_birth]))
        expect(trainee.nationalities.pluck(:name)).to include(nationality_name)
        expect(trainee.email).to eq(student_attributes[:email])
      end

      it "associates the trainer to a provider" do
        expect(trainee.provider.ukprn).to eq(student_attributes[:ukprn])
      end

      it "updates trainee's course details" do
        expect(trainee.course_education_phase).to eq(COURSE_EDUCATION_PHASE_ENUMS[:primary])
        expect(trainee.course_subject_one).to eq(::CourseSubjects::PRIMARY_TEACHING)
        expect(trainee.course_subject_two).to eq(::CourseSubjects::BIOLOGY)
        expect(trainee.course_subject_three).to be_nil
        expect(trainee.course_age_range).to eq(AgeRange::THREE_TO_SEVEN)
        expect(trainee.study_mode).to eq("full_time")
        expect(trainee.itt_start_date).to eq(Date.parse(student_attributes[:itt_start_date]))
        expect(trainee.itt_end_date).to be_nil
        expect(trainee.start_academic_cycle).to eq(start_academic_cycle)
        expect(trainee.end_academic_cycle).to be_nil
        expect(trainee.commencement_date).to eq(Date.parse(student_attributes[:itt_start_date]))
      end

      it "updates the trainee's school and training details" do
        expect(trainee.lead_school.urn).to eq(student_attributes[:lead_school_urn])
        expect(trainee.employing_school.urn).to eq(student_attributes[:employing_school_urn])
        expect(trainee.training_initiative).to eq(ROUTE_INITIATIVES_ENUMS[:no_initiative])
      end

      it "updates the trainee's funding details" do
        expect(trainee.applying_for_bursary).to be(false)
        expect(trainee.applying_for_grant).to be(false)
        expect(trainee.applying_for_scholarship).to be(false)
      end

      it "creates the trainee's degree" do
        expect(trainee.degrees.count).to eq(student_attributes[:degrees].count)
        expect(trainee_degree.locale_code).to eq("uk")
        expect(trainee_degree.uk_degree).to eq("Master of Science")
        expect(trainee_degree.non_uk_degree).to be_nil
        expect(trainee_degree.subject).to eq("Pharmacy")
        expect(trainee_degree.institution).to eq("The Open University")
        expect(trainee_degree.graduation_year).to eq(2005)
        expect(trainee_degree.grade).to eq("First-class honours")
        expect(trainee_degree.other_grade).to be_nil
        expect(trainee_degree.country).to be_nil
      end

      it "creates a trainee HESA metadata record" do
        expect(trainee.hesa_metadatum.study_length).to eq(3)
        expect(trainee.hesa_metadatum.study_length_unit).to eq("years")
        expect(trainee.hesa_metadatum.itt_aim).to eq("Both professional status and academic award")
        expect(trainee.hesa_metadatum.itt_qualification_aim).to eq("Masters, not by research")
        expect(trainee.hesa_metadatum.fundability).to eq("Eligible for funding from the DfE")
        expect(trainee.hesa_metadatum.service_leaver).to eq("Trainee has not left full time employment in the British Army, Royal Air Force or Royal Navy within 5 years of beginning the programme")
        expect(trainee.hesa_metadatum.course_programme_title).to eq("FE Course 1")
        expect(trainee.hesa_metadatum.placement_school_urn).to eq(900000)
        expect(trainee.hesa_metadatum.year_of_course).to eq("0")
      end

      context "when the trn does not exist", feature_integrate_with_dqt: true do
        let(:hesa_stub_attributes) { {} }

        it "enqueues Dqt::RegisterForTrnJob" do
          expect(Dqt::RegisterForTrnJob).to have_received(:perform_later).with(Trainee.last)
        end
      end

      context "when the HESA training route is Provider-led" do
        let(:hesa_stub_attributes) { { training_route: "01", itt_qualification_aim: itt_qualification_aim } }

        context "when the qualification aim is undergrad level" do
          let(:itt_qualification_aim) { "001" }

          it "creates a Provider-led (undergrad) trainee" do
            expect(trainee.training_route).to eq("provider_led_undergrad")
          end
        end

        context "when the qualification aim is not undergrad level" do
          let(:itt_qualification_aim) { "020" }

          it "creates a Provider-led (postgrad) trainee" do
            expect(trainee.training_route).to eq("provider_led_postgrad")
          end
        end

        context "when the qualification aim is nil" do
          let(:itt_qualification_aim) { nil }

          it "creates a Provider-led (undergrad) trainee" do
            expect(trainee.training_route).to eq("provider_led_postgrad")
          end
        end
      end
    end

    context "trainee doesn't exist" do
      describe "#created_from_hesa" do
        subject { trainee.created_from_hesa }

        it { is_expected.to be(true) }
      end
    end

    context "trainee already exists and didn't come from HESA" do
      let(:existing_trn) { Faker::Number.number(digits: 7).to_s }
      let(:hesa_disability_codes) { Hesa::CodeSets::Disabilities::MAPPING.invert }
      let(:hesa_ethnicity_codes) { Hesa::CodeSets::Ethnicities::MAPPING.invert }
      let(:create_custom_state) { create(:trainee, hesa_id: student_attributes[:hesa_id], trn: existing_trn) }

      describe "#created_from_hesa" do
        subject { trainee.created_from_hesa }

        it { is_expected.to be(false) }
      end

      context "when the trainee has a previously saved TRN" do
        context "HESA has a different TRN" do
          it "updates the trainee TRN with the HESA TRN" do
            expect(trainee.trn).to eq(hesa_trn)
          end
        end

        context "HESA TRN is nil" do
          let(:hesa_stub_attributes) { { trn: nil } }

          it "does not overwrite the existing trainee TRN" do
            expect(trainee.trn).to eq(existing_trn)
          end
        end
      end

      context "when ethnicity is missing" do
        let(:hesa_stub_attributes) { { ethnic_background: nil } }

        it "sets the ethnic_group and background to 'Not provided'" do
          expect(trainee.ethnic_group).to eq(Diversities::ETHNIC_GROUP_ENUMS[:not_provided])
          expect(trainee.ethnic_background).to eq(Diversities::NOT_PROVIDED)
        end
      end

      context "when ethnicity is explicitly 'not provided'" do
        let(:hesa_stub_attributes) do
          { ethnic_background: hesa_disability_codes[Diversities::NOT_PROVIDED] }
        end

        it "sets the ethnic_group and background to 'Not provided'" do
          expect(trainee.ethnic_group).to eq(Diversities::ETHNIC_GROUP_ENUMS[:not_provided])
          expect(trainee.ethnic_background).to eq(Diversities::NOT_PROVIDED)
        end
      end

      context "when neither ethnicity nor disabilities are disclosed" do
        let(:hesa_stub_attributes) do
          {
            ethnic_background: hesa_disability_codes[Diversities::INFORMATION_REFUSED],
            disability: nil,
          }
        end

        it "sets the diversity disclosure to 'diversity_not_disclosed'" do
          expect(trainee.diversity_disclosure).to eq(Diversities::DIVERSITY_DISCLOSURE_ENUMS[:diversity_not_disclosed])
        end
      end

      context "when just disability is disclosed" do
        let(:hesa_stub_attributes) do
          {
            ethnic_background: hesa_ethnicity_codes[Diversities::INFORMATION_REFUSED],
            disability: hesa_disability_codes[Diversities::LEARNING_DIFFICULTY],
          }
        end

        it "sets the diversity disclosure to 'diversity_disclosed'" do
          expect(trainee.diversity_disclosure).to eq(Diversities::DIVERSITY_DISCLOSURE_ENUMS[:diversity_disclosed])
        end
      end

      context "when disability is 'MULTIPLE_DISABILITIES'" do
        let(:trainee_disability) { trainee.trainee_disabilities.last }
        let(:create_custom_state) { create(:disability, name: Diversities::OTHER) }
        let(:hesa_stub_attributes) do
          {
            ethnic_background: hesa_ethnicity_codes[Diversities::INFORMATION_REFUSED],
            disability: hesa_disability_codes[Diversities::MULTIPLE_DISABILITIES],
          }
        end

        it "saves the disability as 'other' and sets the additional_diversity text" do
          expect(trainee_disability.additional_disability).to eq(Trainees::CreateFromHesa::MULTIPLE_DISABILITIES_TEXT)
          expect(trainee_disability.disability.name).to eq(Diversities::OTHER)
        end
      end

      context "when just ethnicity is disclosed" do
        let(:hesa_stub_attributes) { { ethnic_background: hesa_ethnicity_codes[Diversities::AFRICAN] } }

        it "sets the diversity disclosure to 'diversity_disclosed'" do
          expect(trainee.diversity_disclosure).to eq(Diversities::DIVERSITY_DISCLOSURE_ENUMS[:diversity_disclosed])
        end
      end

      context "when ethnicity is information_refused" do
        let(:hesa_stub_attributes) { { ethnic_background: hesa_ethnicity_codes[Diversities::INFORMATION_REFUSED] } }

        it "sets the ethnic_group to 'Not provided'" do
          expect(trainee.ethnic_group).to eq(Diversities::ETHNIC_GROUP_ENUMS[:not_provided])
        end
      end

      context "when commencement_date is not null" do
        let(:hesa_stub_attributes) { { commencement_date: "2020-09-27" } }

        it "uses the commencement_date" do
          expect(trainee.commencement_date).to eq(Date.parse("2020-09-27"))
        end
      end

      context "when end date is available" do
        let(:date) { "2020-12-12" }
        let(:hesa_reasons_for_leaving_codes) { Hesa::CodeSets::ReasonsForLeavingCourse::MAPPING.invert }

        context "and the trainee did not complete the course" do
          let(:hesa_stub_attributes) do
            {
              end_date: date,
              reason_for_leaving: hesa_reasons_for_leaving_codes[WithdrawalReasons::HEALTH_REASONS],
            }
          end

          it "creates a withdrawn trainee with the relevant details" do
            expect(trainee.state).to eq("withdrawn")
            expect(trainee.withdraw_date).to eq(date)
            expect(trainee.withdraw_reason).to eq(WithdrawalReasons::HEALTH_REASONS)
          end
        end

        context "and the reason for completion is 'Completion of course - result unknown'" do
          let(:hesa_modes) { Hesa::CodeSets::Modes::MAPPING.invert }

          let(:hesa_stub_attributes) do
            {
              end_date: date,
              reason_for_leaving: hesa_reasons_for_leaving_codes[Hesa::CodeSets::ReasonsForLeavingCourse::UNKNOWN_COMPLETION],
              mode: hesa_modes[Hesa::CodeSets::Modes::DORMANT_FULL_TIME],
            }
          end

          it "creates a deferred trainee with the relevant details" do
            expect(trainee.defer_date).to eq(Date.parse(date))
            expect(trainee.state).to eq("deferred")
          end
        end
      end

      context "when bursary is available" do
        let(:hesa_bursary_level_codes) { Hesa::CodeSets::BursaryLevels::MAPPING.invert }
        let(:hesa_stub_attributes) do
          { bursary_level: hesa_bursary_level_codes[Dttp::CodeSets::BursaryDetails::UNDERGRADUATE_BURSARY] }
        end

        it "uses the MapFundingFromDttpEntityId service to determine bursary information" do
          expect(trainee.applying_for_bursary).to be(true)
        end
      end

      context "when training initiative is available and mappable" do
        let(:hesa_training_initiative_codes) { Hesa::CodeSets::TrainingInitiatives::MAPPING.invert }

        let(:hesa_stub_attributes) do
          { training_initiative: hesa_training_initiative_codes[ROUTE_INITIATIVES_ENUMS[:now_teach]] }
        end

        it "maps the the HESA code to the register enum" do
          expect(trainee.training_initiative).to eq(ROUTE_INITIATIVES_ENUMS[:now_teach])
        end
      end

      context "trainee's course is in the primary age but subject isn't" do
        let(:hesa_stub_attributes) do
          {
            course_age_range: hesa_age_range_codes[AgeRange::SEVEN_TO_ELEVEN],
            course_subject_one: hesa_course_subject_codes[CourseSubjects::DESIGN],
          }
        end

        it "adds 'primary teaching' and places it in the course_subject_one column" do
          expect(trainee.course_subject_one).to eq(CourseSubjects::PRIMARY_TEACHING)
          expect(trainee.course_subject_two).to eq(CourseSubjects::DESIGN)
        end
      end

      context "trainee's course is in the primary age but primary subject not the first subject" do
        let(:hesa_stub_attributes) do
          {
            course_age_range: hesa_age_range_codes[AgeRange::SEVEN_TO_ELEVEN],
            course_subject_one: hesa_course_subject_codes[CourseSubjects::DESIGN],
            course_subject_two: hesa_course_subject_codes[CourseSubjects::PRIMARY_TEACHING],
          }
        end

        it "moves 'primary teaching' to be the first subject" do
          expect(trainee.course_subject_one).to eq(CourseSubjects::PRIMARY_TEACHING)
          expect(trainee.course_subject_two).to eq(CourseSubjects::DESIGN)
        end
      end
    end
  end
end
