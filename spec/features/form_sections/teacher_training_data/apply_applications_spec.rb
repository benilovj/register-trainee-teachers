# frozen_string_literal: true

require "rails_helper"

feature "apply registrations", type: :feature do
  include CourseDetailsHelper

  let(:itt_start_date) { Date.new(Settings.current_default_course_year, 9, 1) }
  let(:itt_end_date) { itt_start_date + 1.year }

  background do
    given_i_am_authenticated
    and_a_trainee_exists_created_from_apply
    given_i_am_on_the_review_draft_page
  end

  describe "with a missing course code against the trainee" do
    let(:subjects) { ["History"] }

    scenario "reviewing course" do
      given_the_trainee_does_not_have_a_course_uuid
      when_i_enter_the_course_details_page
      then_i_am_on_the_publish_course_details_page
    end
  end

  describe "with a course that doesn't require selecting a specialism" do
    let(:subjects) { ["History"] }

    scenario "reviewing course" do
      when_i_enter_the_course_details_page
      and_i_confirm_the_course_details
      and_i_enter_itt_dates
      then_i_am_redirected_to_the_apply_applications_confirm_course_page
      and_i_should_see_the_subject_specialism("History")
      and_i_confirm_the_course
      then_i_am_redirected_to_the_review_draft_page
    end
  end

  describe "with a course that requires selecting multiple specialisms" do
    let(:subjects) { ["Art and design"] }

    scenario "selecting specialisms" do
      when_i_enter_the_course_details_page
      and_i_confirm_the_course_details
      and_i_select_a_specialism("Graphic design")
      and_i_enter_itt_dates
      then_i_am_redirected_to_the_apply_applications_confirm_course_page
      and_i_should_see_the_subject_specialism("Graphic design")
    end
  end

  describe "with a course that requires selecting multiple language specialisms" do
    let(:subjects) { ["Modern languages (other)"] }

    scenario "selecting languages" do
      when_i_enter_the_course_details_page
      and_i_confirm_the_course_details
      and_i_choose_my_languages
      and_i_enter_itt_dates
      then_i_am_redirected_to_the_apply_applications_confirm_course_page
      and_i_should_see_the_subject_specialism("Modern languages")
    end
  end

private

  def training_route
    # NOTE: `pg_teaching_apprenticeship` has a different journey covered by it's own spec

    (TRAINING_ROUTES_FOR_COURSE.keys - [TRAINING_ROUTE_ENUMS[:pg_teaching_apprenticeship]]).sample
  end

  def and_a_trainee_exists_created_from_apply
    given_a_trainee_exists(
      :with_apply_application, :with_related_courses, courses_count: 1, subject_names: subjects, training_route: training_route
    )

    Course.first.tap do |course|
      trainee.update(course_uuid: course.uuid)
    end
  end

  def given_the_trainee_does_not_have_a_course_uuid
    trainee.update(course_uuid: nil)
  end

  def then_the_section_should_be(status)
    expect(review_draft_page.course_details.status.text).to eq(status)
  end

  def then_i_am_on_the_publish_course_details_page
    expect(publish_course_details_page).to be_displayed(id: trainee.slug)
  end

  def when_i_visit_the_apply_applications_course_details_page
    apply_registrations_course_details_page.load(id: trainee.slug)
  end

  def then_i_am_redirected_to_the_apply_applications_confirm_course_page
    expect(apply_registrations_confirm_course_page).to be_displayed(id: trainee.slug)
  end

  def when_i_enter_the_course_details_page
    review_draft_page.course_details.link.click
  end

  def and_i_confirm_the_course_details
    apply_registrations_course_details_page.course_options.first.choose
    apply_registrations_course_details_page.continue.click
  end

  def and_i_choose_my_languages
    language_specialism_page.language_specialism_options.first.check
    language_specialism_page.submit_button.click
  end

  def and_i_confirm_the_course
    apply_registrations_confirm_course_page.confirm.uncheck
    apply_registrations_confirm_course_page.submit_button.click
  end

  def and_i_should_see_the_subject_specialism(description)
    expect(apply_registrations_confirm_course_page.subject_description).to eq(description)
  end

  def and_i_select_a_specialism(specialism)
    subject_specialism_page.specialism_options.find { |o| o.label.text == specialism }.choose
    subject_specialism_page.submit_button.click
  end
end
