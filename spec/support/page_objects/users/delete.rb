# frozen_string_literal: true

module PageObjects
  module Users
    class Delete < PageObjects::Base
      set_url "system-admin/users/{id}/delete"

      element :delete_a_user, ".govuk-button--warning"
    end
  end
end
