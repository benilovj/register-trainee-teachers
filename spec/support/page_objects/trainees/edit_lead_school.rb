# frozen_string_literal: true

module PageObjects
  module Trainees
    class EditLeadSchool < PageObjects::Base
      set_url "/trainees/{trainee_id}/lead-schools/edit"

      element :lead_school, "#lead-school-form-lead-school-id-field"
      element :no_js_lead_school, "#lead-school-form-lead-school-id-field"
      element :autocomplete_list_item, "#lead-school-form-lead-school-id-field__listbox li:first-child"
      element :submit, 'input.govuk-button[type="submit"]'
    end
  end
end
