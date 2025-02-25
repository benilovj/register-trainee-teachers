# frozen_string_literal: true

require "rails_helper"

module Trainees
  describe Filter do
    subject { described_class.call(trainees: trainees, filters: filters) }

    let(:draft_trainee) { create(:trainee, :incomplete_draft, first_names: "Draft") }
    let(:apply_draft_trainee) { create(:trainee, :with_apply_application, first_names: "Apply") }
    let(:filters) { nil }
    let(:trainees) { Trainee.all }

    before do
      create(:academic_cycle, cycle_year: 2019)
      create(:academic_cycle, cycle_year: 2020)
    end

    it { is_expected.to match_array(trainees) }

    context "empty trainee exists" do
      let!(:empty_trainee) do
        Trainee.create(provider_id: draft_trainee.provider.id,
                       training_route: TRAINING_ROUTE_ENUMS[:assessment_only])
      end

      it { is_expected.not_to include(empty_trainee) }
    end

    context "with training_route filter" do
      let!(:provider_led_postgrad_trainee) { create(:trainee, :provider_led_postgrad) }
      let(:filters) { { training_route: TRAINING_ROUTE_ENUMS[:provider_led_postgrad] } }

      it { is_expected.to eq([provider_led_postgrad_trainee]) }
    end

    context "with level filter" do
      let!(:early_years_trainee) { create(:trainee, :early_years_undergrad) }
      let!(:primary_trainee) { create(:trainee, :with_primary_education) }
      let!(:secondary_trainee) { create(:trainee, :with_secondary_education) }

      context "early_years" do
        let(:filters) { { level: %w[early_years] } }

        it { is_expected.to contain_exactly(early_years_trainee) }
      end

      context "early_years and primary" do
        let(:filters) { { level: %w[early_years primary] } }

        it { is_expected.to contain_exactly(early_years_trainee, primary_trainee) }
      end

      context "primary" do
        let(:filters) { { level: %w[primary] } }

        it { is_expected.to contain_exactly(primary_trainee) }
      end

      context "secondary" do
        let(:filters) { { level: %w[secondary] } }

        it { is_expected.to contain_exactly(secondary_trainee) }
      end
    end

    context "with status filter" do
      let!(:submitted_for_trn_trainee) { create(:trainee, :submitted_for_trn, :itt_start_date_in_the_past) }
      let!(:qts_awarded_trainee) { create(:trainee, :qts_awarded, :itt_start_date_in_the_past) }
      let!(:eyts_awarded_trainee) { create(:trainee, :eyts_awarded, :itt_start_date_in_the_past) }
      let!(:not_yet_started_trainee) { create(:trainee, :trn_received, :itt_start_date_in_the_future) }
      let!(:withdrawn_trainee) { create(:trainee, :withdrawn, :itt_start_date_in_the_past) }
      let!(:deferred_trainee) { create(:trainee, :deferred, :itt_start_date_in_the_past) }

      context "with in_training" do
        let(:filters) { { status: %w[in_training] } }

        it { is_expected.to contain_exactly(submitted_for_trn_trainee) }
      end

      context "with awarded" do
        let(:filters) { { status: %w[awarded] } }

        it { is_expected.to contain_exactly(qts_awarded_trainee, eyts_awarded_trainee) }
      end

      context "with in_training, awarded" do
        let(:filters) { { status: %w[in_training awarded] } }

        it { is_expected.to contain_exactly(submitted_for_trn_trainee, qts_awarded_trainee, eyts_awarded_trainee) }
      end

      context "with withdrawn" do
        let(:filters) { { status: %w[withdrawn] } }

        it { is_expected.to contain_exactly(withdrawn_trainee) }
      end

      context "with deferred" do
        let(:filters) { { status: %w[deferred] } }

        it { is_expected.to contain_exactly(deferred_trainee) }
      end

      context "with course not yet started" do
        let(:filters) { { status: %w[course_not_yet_started] } }

        it { is_expected.to contain_exactly(not_yet_started_trainee) }
      end
    end

    context "with subject filter" do
      let(:subject_name) { CourseSubjects::BIOLOGY }
      let!(:trainee_with_subject) { create(:trainee, course_subject_one: subject_name) }
      let(:filters) { { subject: subject_name } }

      it { is_expected.to eq([trainee_with_subject]) }
    end

    context "with subject filter set to Sciences - biology, chemistry, physics" do
      let(:subject_name) { Filter::ALL_SCIENCES_FILTER }
      let!(:trainee_with_biology) { create(:trainee, course_subject_one: "Biology") }
      let!(:trainee_with_chemistry) { create(:trainee, course_subject_one: "Chemistry") }
      let!(:trainee_with_physics) { create(:trainee, course_subject_one: "Physics") }
      let(:filters) { { subject: subject_name } }

      it { is_expected.to match_array([trainee_with_biology, trainee_with_chemistry, trainee_with_physics]) }
    end

    context "with text_search filter" do
      let!(:named_trainee) { create(:trainee, first_names: "Boaty McBoatface") }
      let(:filters) { { text_search: "Boaty" } }

      it { is_expected.to eq([named_trainee]) }
    end

    context "with record_completion filter" do
      let!(:non_draft_trainee) { create(:trainee, :submitted_for_trn) }

      context "complete" do
        let(:filters) { { record_completion: ["complete"] } }

        it { is_expected.to match_array([non_draft_trainee]) }
      end

      context "incomplete" do
        let(:filters) { { record_completion: ["incomplete"] } }

        it { is_expected.to match_array([draft_trainee, apply_draft_trainee]) }
      end
    end

    context "start and end year filters" do
      let(:current_year) { Time.zone.now.year }
      let(:academic_cycle) { create(:academic_cycle, :current) }

      context "with start_year filter" do
        let!(:trainee) { create(:trainee, start_academic_cycle: academic_cycle) }
        let(:filters) { { start_year: "#{current_year - 1} to #{current_year}" } }

        context "trainee starting in that year" do
          it "returns the trainee" do
            expect(subject).to match_array([trainee])
          end
        end

        context "trainee not starting in that year" do
          let(:academic_cycle) { create(:academic_cycle, next_cycle: true) }

          before { create(:academic_cycle, :current) }

          it "does not return the trainee" do
            expect(subject).to be_empty
          end
        end

        context "trainee start_academic_cycle is blank" do
          let(:academic_cycle) { nil }

          before { create(:academic_cycle, :current) }

          it "returns the trainee" do
            expect(subject).to match_array([trainee])
          end
        end
      end

      context "with end_year filter" do
        let!(:trainee) { create(:trainee, end_academic_cycle: academic_cycle) }
        let(:filters) { { end_year: "#{current_year - 1} to #{current_year}" } }

        context "trainee ending in that year" do
          it "returns the trainee" do
            expect(subject).to match_array([trainee])
          end
        end

        context "trainee not ending in that year" do
          let(:academic_cycle) { create(:academic_cycle, next_cycle: true) }

          before { create(:academic_cycle, :current) }

          it "does not return the trainee" do
            expect(subject).to be_empty
          end
        end

        context "trainee end_academic_cycle is blank" do
          let(:academic_cycle) { nil }

          before { create(:academic_cycle, :current) }

          it "returns the trainee" do
            expect(subject).to match_array([trainee])
          end
        end
      end
    end

    describe "record source filter" do
      let!(:dttp_trainee) { create(:trainee, :created_from_dttp, first_names: "DTTP") }
      let(:filters) { { record_source: filter_value } }

      context "with record_source filter set to apply" do
        let(:filter_value) { %w[apply] }

        it { is_expected.to contain_exactly(apply_draft_trainee) }
      end

      context "with record_source filter set to manual" do
        let(:filter_value) { %w[manual] }

        it { is_expected.to contain_exactly(draft_trainee) }
      end

      context "with record_source filter set to dttp" do
        let(:filter_value) { %w[dttp] }

        it { is_expected.to contain_exactly(dttp_trainee) }
      end

      context "with record_source filter set to both manual and apply" do
        let(:filter_value) { %w[apply manual] }

        it { is_expected.to match_array([apply_draft_trainee, draft_trainee]) }
      end

      context "with record_source filter set to both dttp and apply" do
        let(:filter_value) { %w[apply dttp] }

        it { is_expected.to match_array([apply_draft_trainee, dttp_trainee]) }
      end

      context "with record_source filter set to both dttp and manual" do
        let(:filter_value) { %w[manual dttp] }

        it { is_expected.to match_array([draft_trainee, dttp_trainee]) }
      end

      context "with record_source filter set to both dttp, apply and manual" do
        let(:filter_value) { %w[apply dttp manual] }

        it { is_expected.to match_array([apply_draft_trainee, dttp_trainee, draft_trainee]) }
      end
    end

    context "with study_mode filter set to full time" do
      let!(:full_time_trainee) { create(:trainee, study_mode: "full_time", training_route: "early_years_salaried") }
      let(:filters) { { study_mode: %w[full_time] } }

      it { is_expected.to contain_exactly(full_time_trainee) }
    end

    context "with study_mode filter set to part time" do
      let!(:full_time_trainee) { create(:trainee, study_mode: "full_time", training_route: "early_years_salaried") }
      let!(:part_time_trainee) { create(:trainee, study_mode: "part_time", training_route: "early_years_salaried") }
      let(:filters) { { study_mode: %w[part_time] } }

      it { is_expected.to contain_exactly(part_time_trainee) }
    end

    context "with study_mode filter set to full time and part time" do
      let!(:full_time_trainee) { create(:trainee, study_mode: "full_time", training_route: "early_years_salaried") }
      let!(:part_time_trainee) { create(:trainee, study_mode: "part_time", training_route: "early_years_salaried") }
      let(:filters) { { study_mode: %w[full_time part_time] } }

      it { is_expected.to contain_exactly(draft_trainee, apply_draft_trainee, full_time_trainee, part_time_trainee) }
    end

    context "when courses are assesment only and study mode filter is part time" do
      let!(:full_time_trainee) { create(:trainee, study_mode: "full_time", training_route: "assessment_only") }
      let!(:part_time_trainee) { create(:trainee, study_mode: "part_time", training_route: "assessment_only") }
      let(:filters) { { study_mode: %w[part_time] } }

      it { is_expected.to be_empty }
    end

    describe "error is not raised" do
      let(:trigger) do
        # NOTE: forcing the subject to deserialise
        subject.count
      end

      let(:subject_name) { CourseSubjects::BIOLOGY }
      let!(:trainee_with_subject) { create(:trainee, trainee_id: "bug", course_subject_one: subject_name) }
      let(:filters) { { subject: subject_name, text_search: "bug" } }

      it { expect { trigger } .not_to raise_error }
    end
  end
end
