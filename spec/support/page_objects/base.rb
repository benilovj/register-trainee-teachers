# frozen_string_literal: true

module PageObjects
  module Helpers
    def set_date_fields(field_prefix, date_string)
      day, month, year = date_string.split("/")
      send("#{field_prefix}_day").set(day)
      send("#{field_prefix}_month").set(month)
      send("#{field_prefix}_year").set(year)
    end
  end

  class Base < SitePrism::Page; end

  class Accessibility < PageObjects::Base
    set_url "/accessibility"

    element :page_heading, ".govuk-heading-l"
  end
end
