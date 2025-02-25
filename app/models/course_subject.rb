# frozen_string_literal: true

class CourseSubject < ApplicationRecord
  belongs_to :course
  belongs_to :subject

  validates :course, uniqueness: { scope: :subject }
end
