# frozen_string_literal: true

module Funding
  class PaymentSchedule < ApplicationRecord
    self.table_name = "funding_payment_schedules"

    belongs_to :payable, polymorphic: true
    has_many :rows,
             class_name: "Funding::PaymentScheduleRow",
             dependent: :destroy,
             foreign_key: :funding_payment_schedule_id,
             inverse_of: :payment_schedule

    def start_year
      return if rows.empty?
      return if rows.first.amounts.empty?

      rows.first.amounts.minimum(:year)
    end

    def end_year
      return if rows.empty?
      return if rows.first.amounts.empty?

      rows.first.amounts.maximum(:year)
    end
  end
end
