# frozen_string_literal: true

require_relative "base"

module PageObjects
  module Sections
    class ContactDetails < PageObjects::Sections::Base
      element :link, ".govuk-link"
      element :status, ".govuk-tag"
    end
  end
end
