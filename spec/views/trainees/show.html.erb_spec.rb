# frozen_string_literal: true

require "rails_helper"

describe "trainees/show.html.erb", "feature_routes.provider_led_postgrad": true do
  before do
    assign(:trainee, trainee)
    assign(:current_user, current_user)
    without_partial_double_verification do
      allow(view).to receive(:trainee_editable?).and_return(true)
    end
  end

  context "placements enabled", feature_placements: true do
    before do
      render
    end

    context "with an Assessment only trainee" do
      let(:trainee) { create(:trainee, :submitted_for_trn) }
      let(:current_user) { create(:user, :system_admin) }

      it "does not render the placement details component" do
        expect(rendered).not_to have_text("Placement details")
      end
    end

    context "with a Provider-led (postgrad) trainee" do
      let(:trainee) { create(:trainee, :submitted_for_trn, :provider_led_postgrad) }
      let(:current_user) { create(:user, :system_admin) }

      it "renders the placement details component" do
        expect(rendered).to have_text("Placement details")
      end
    end

    context "with non early year trainees that have status trn_received" do
      let(:non_early_year_trainees) { TRAINING_ROUTE_ENUMS.values_at(:assessment_only, :provider_led_postgrad, :school_direct_tuition_fee, :school_direct_salaried) }
      let(:trainee) { create(:trainee, :trn_received, non_early_year_trainees.sample) }
      let(:current_user) { create(:user, :system_admin) }

      it "renders the correct text on the button" do
        expect(rendered).to have_text("Recommend trainee for QTS")
      end
    end

    context "with early year trainees that have status trn_received" do
      let(:early_years_trainees) { TRAINING_ROUTE_ENUMS.values_at(:early_years_assessment_only, :early_years_postgrad, :early_years_salaried, :early_years_undergrad) }
      let(:current_user) { create(:user, :system_admin) }
      let(:trainee) { create(:trainee, :trn_received, early_years_trainees.sample) }

      it "renders the correct text on the button" do
        expect(rendered).to have_text("Recommend trainee for EYTS")
      end
    end
  end

  context "placements disabled", feature_placements: false do
    before do
      render
    end

    context "with a Provider-led (postgrad) trainee" do
      let(:current_user) { create(:user, :system_admin) }
      let(:trainee) { create(:trainee, :submitted_for_trn, :provider_led_postgrad) }

      it "doesn't render the placement details component" do
        expect(rendered).not_to have_text("Placement details")
      end
    end
  end
end
