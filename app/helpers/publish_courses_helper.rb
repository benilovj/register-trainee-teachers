# frozen_string_literal: true

module PublishCoursesHelper
  def apply_course_summary(course)
    "#{course.name} (#{course.code})".strip
  end

  def apply_course_and_route_summary(course)
    t(".summary_with_route", summary: apply_course_summary(course), route: t("activerecord.attributes.trainee.training_routes.#{course.route}"))
  end

  def course_summary_text_for(trainee, course)
    summary_with_route = t(".summary_with_route", summary: course.summary, route: t("activerecord.attributes.trainee.training_routes.#{course.route}"))
    trainee.apply_application? ? summary_with_route : course.summary
  end

  def courses_fieldset_text_for(trainee)
    return t("views.forms.publish_course_details.all_courses_message") if trainee.apply_application?

    t("views.forms.publish_course_details.route_message", route: route_title(trainee.training_route))
  end
end
