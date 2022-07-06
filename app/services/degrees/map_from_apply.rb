# frozen_string_literal: true

module Degrees
  class MapFromApply
    include ServicePattern
    include MappingsHelper

    def initialize(attributes:)
      @attributes = attributes
    end

    def call
      common_params.merge(degree_params)
    end

  private

    attr_reader :attributes

    def degree_params
      uk_degree? ? uk_degree_params : non_uk_degree_params
    end

    def common_params
      {
        is_apply_import: true,
        graduation_year: attributes["award_year"],
      }.merge(subject_params)
    end

    def uk_degree_params
      {
        locale_code: Trainee.locale_codes[:uk],
      }.merge(qualification_type_params)
       .merge(grade_params)
       .merge(institution_params)
    end

    def non_uk_degree_params
      {
        locale_code: Trainee.locale_codes[:non_uk],
        non_uk_degree: attributes["comparable_uk_degree"],
        country: country,
      }
    end

    def qualification_type_params
      qualification_type = find_dfe_reference_type

      if qualification_type
        { uk_degree: qualification_type[:name], uk_degree_uuid: qualification_type[:id] }
      else
        { uk_degree: attributes["qualification_type"] }
      end
    end

    def institution_params
      institution = find_dfe_reference_institution

      if institution
        { institution: institution[:name], institution_uuid: institution[:id] }
      else
        { institution: attributes["institution_details"] }
      end
    end

    def subject_params
      subject = find_dfe_reference_subject

      if subject
        { subject: subject[:name], subject_uuid: subject[:id] }
      else
        { subject: attributes["subject"] }
      end
    end

    def grade_params
      grade = find_dfe_reference_grade

      if Degree::GRADES.include?(grade[:name])
        { grade: grade[:name], grade_uuid: grade[:id], other_grade: nil }
      else
        { grade: Degree::OTHER_GRADE, grade_uuid: grade[:id], other_grade: grade[:name] }
      end
    end

    def uk_degree?
      attributes["non_uk_qualification_type"].nil?
    end

    def find_dfe_reference_subject
      find_dfe_reference_item(:subjects,
                              uuid: attributes["subject_uuid"],
                              hesa_itt_code: sanitised_hesa(attributes["hesa_degsbj"]),
                              name: attributes["subject"])
    end

    def find_dfe_reference_type
      find_dfe_reference_item(:types,
                              uuid: attributes["degree_type_uuid"],
                              hesa_itt_code: sanitised_hesa(attributes["hesa_degtype"]),
                              abbreviation: attributes["qualification_type"])
    end

    def find_dfe_reference_institution
      find_dfe_reference_item(:institutions,
                              uuid: attributes["institution_uuid"],
                              hesa_itt_code: sanitised_hesa(attributes["hesa_degest"]),
                              name: attributes["institution_details"].split(",").first)
    end

    def find_dfe_reference_grade
      find_dfe_reference_item(:grades,
                              uuid: attributes["grade_uuid"],
                              hesa_itt_code: sanitised_hesa(attributes["hesa_degclss"]),
                              name: attributes["grade"])
    end

    def country
      Dttp::CodeSets::Countries::MAPPING.find { |_, v| v[:country_code] == attributes["hesa_degctry"] }&.first
    end

    def find_dfe_reference_item(list_type, filters)
      DfE::ReferenceData::Degrees.const_get(list_type.to_s.upcase).all.find do |record|
        filters.compact.any? do |field, value|
          same_string?(record[field], value) || almost_identical?(record[field], value)
        end
      end
    end
  end
end
