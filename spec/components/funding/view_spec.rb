# frozen_string_literal: true

require "rails_helper"

module Funding
  describe View do
    let(:data_model) { Funding::FormValidator.new(trainee) }

    before { render_inline(View.new(data_model: trainee, editable: true)) }

    context "with tieried bursary" do
      let(:trainee) do
        build(:trainee,
              :early_years_postgrad,
              :with_course_allocation_subject,
              applying_for_bursary: true,
              bursary_tier: BURSARY_TIERS.keys.first)
      end

      it "renders tiered bursary text" do
        expect(rendered_component).to have_text("Applied for Tier 1")
        expect(rendered_component).to have_text("£5,000 estimated bursary")
      end
    end

    context "on opt-in (undergrad) route" do
      let(:state) { :draft }
      let(:route) { "opt_in_undergrad" }
      let(:training_initiative) { ROUTE_INITIATIVES_ENUMS.keys.first }
      let(:trainee) do
        build(:trainee,
              state,
              :with_start_date,
              :with_study_mode_and_course_dates,
              training_initiative: training_initiative,
              training_route: route,
              applying_for_bursary: true,
              course_subject_one: subject_specialism.name)
      end

      let(:subject_specialism) { create(:subject_specialism, name: AllocationSubjects::MATHEMATICS) }
      let(:amount) { 9000 }
      let(:funding_method) { create(:funding_method, training_route: route, amount: amount) }

      context "when there is a bursary available" do
        before do
          create(:funding_method_subject,
                 funding_method: funding_method,
                 allocation_subject: subject_specialism.allocation_subject)
          render_inline(View.new(data_model: data_model))
        end

        it "renders if the trainee selects mathematics" do
          expect(rendered_component).to have_text("£9,000 estimated bursary")
        end
      end

      context "when there is no bursary available" do
        before do
          render_inline(View.new(data_model: trainee))
        end

        it "doesn't render if the trainee selects drama" do
          expect(rendered_component).not_to have_text("Bursary applied for")
        end
      end
    end

    context "assessment only route" do
      let(:state) { :draft }
      let(:route) { "assessment_only" }
      let(:training_initiative) { ROUTE_INITIATIVES_ENUMS.keys.first }

      let(:trainee) do
        build(:trainee,
              state,
              :with_start_date,
              :with_study_mode_and_course_dates,
              training_initiative: training_initiative,
              training_route: route,
              applying_for_bursary: applying_for_bursary,
              course_subject_one: course_subject_one)
      end

      let(:course_subject_one) { nil }
      let(:applying_for_bursary) { nil }

      describe "on training initiative" do
        let(:training_initiative) { ROUTE_INITIATIVES.keys.first }

        it "renders" do
          expect(rendered_component).to have_text(t("activerecord.attributes.trainee.training_initiatives.#{training_initiative}"))
        end

        it "has correct change link" do
          expect(rendered_component).to have_link(href: "/trainees/#{trainee.slug}/funding/training-initiative/edit")
        end

        describe "has no bursary" do
          before do
            create(:funding_method)
            render_inline(View.new(data_model: data_model))
          end

          it "doesnt not render bursary row" do
            expect(rendered_component).not_to have_text("Bursary applied for")
          end

          context "and it non-draft" do
            let(:state) { :trn_received }

            before do
              render_inline(View.new(data_model: trainee))
            end

            it "renders bursary not available" do
              expect(rendered_component).to have_text("Not applicable")
            end
          end
        end

        describe "has bursary" do
          let(:trainee) { create(:trainee, :with_provider_led_bursary, funding_amount: 24000, applying_for_bursary: applying_for_bursary) }

          before do
            render_inline(View.new(data_model: trainee, editable: true))
          end

          describe "bursary funded" do
            let(:applying_for_bursary) { true }

            it "renders" do
              expect(rendered_component).to have_text("Bursary applied for")
              expect(rendered_component).to have_text("£24,000 estimated bursary")
            end

            it "has correct change link" do
              expect(rendered_component).to have_link(href: "/trainees/#{trainee.slug}/funding/bursary/edit")
            end
          end

          describe "not bursary funded" do
            let(:applying_for_bursary) { false }

            it "renders" do
              expect(rendered_component).to have_text("Not funded")
              expect(rendered_component).not_to have_text("£24,000 estimated bursary")
            end

            it "has correct change link" do
              expect(rendered_component).to have_link(href: "/trainees/#{trainee.slug}/funding/bursary/edit")
            end
          end
        end
      end

      describe "not on training initiative" do
        let(:training_initiative) { "no_initiative" }

        it "renders" do
          expect(rendered_component).to have_text(t("activerecord.attributes.trainee.training_initiatives.#{training_initiative}"))
        end

        it "has correct change links" do
          expect(rendered_component).to have_link(href: "/trainees/#{trainee.slug}/funding/training-initiative/edit")
        end
      end
    end

    context "with grant" do
      let(:trainee) { create(:trainee, :with_grant, funding_amount: 25000, applying_for_grant: applying_for_grant) }

      before do
        render_inline(View.new(data_model: trainee, editable: true))
      end

      context "when trainee applying_for_grant is true" do
        let(:applying_for_grant) { true }

        it "renders grant text" do
          expect(rendered_component).to have_text("Grant applied for")
          expect(rendered_component).to have_text("£25,000 estimated grant")
        end
      end

      context "when trainee applying_for_grant is false" do
        let(:applying_for_grant) { false }

        it "renders grant text" do
          expect(rendered_component).to have_text("Not grant funded")
        end

        it "has correct change link" do
          expect(rendered_component).to have_link(href: "/trainees/#{trainee.slug}/funding/bursary/edit", text: "Change")
        end
      end

      context "when trainee applying_for_grant is nil" do
        let(:applying_for_grant) { nil }

        it "renders grant text" do
          expect(rendered_component).to have_text("Funding method is missing")
        end

        it "has correct change link" do
          expect(rendered_component).to have_link(href: "/trainees/#{trainee.slug}/funding/bursary/edit", text: "Enter an answer")
        end
      end
    end

    describe "when we don't know the funding rules for the trainee's cycle" do
      let(:trainee) { create(:trainee, :with_start_date, applying_for_bursary: true) }

      it "doesn't render the funding row" do
        expect(rendered_component).not_to have_text("Funding method")
      end
    end
  end
end
