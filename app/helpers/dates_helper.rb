# frozen_string_literal: true

module DatesHelper
  def date_before_itt_start_date?(commencement_date, itt_start_date)
    return false if itt_start_date.blank?

    commencement_date < itt_start_date
  end

  def valid_date?(date_args)
    Date.valid_date?(*date_args) && date_args.all?(&:positive?)
  end
end
