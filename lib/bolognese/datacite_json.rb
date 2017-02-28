module Bolognese
  class DataciteJson < Metadata

    DC_TO_SO_TRANSLATIONS = {
      "Audiovisual" => "VideoObject",
      "Collection" => "Collection",
      "Dataset" => "Dataset",
      "Event" => "Event",
      "Image" => "ImageObject",
      "InteractiveResource" => nil,
      "Model" => nil,
      "PhysicalObject" => nil,
      "Service" => "Service",
      "Software" => "SoftwareSourceCode",
      "Sound" => "AudioObject",
      "Text" => "ScholarlyArticle",
      "Workflow" => nil,
      "Other" => "CreativeWork"
    }

    SCHEMA = File.expand_path("../../../resources/kernel-4.0/metadata.xsd", __FILE__)

    def initialize(string: nil, regenerate: false)
      if string.present?
        @raw = string
      end
    end

    def metadata
      @metadata ||= raw.present? ? Maremma.from_json(raw).fetch("resource", {}) : {}
    end

    def exists?
      metadata.present?
    end

    def valid?
      errors.blank?
    end

    def schema_version
      metadata.fetch("xmlns", nil)
    end

    def doi
      metadata.fetch("identifier", {}).fetch("__content__", nil)
    end

    def id
      normalize_doi(doi)
    end

    def resource_type_general
      metadata.dig("resourceType", "resourceTypeGeneral")
    end

    def type
      DC_TO_SO_TRANSLATIONS[resource_type_general.to_s.dasherize] || "CreativeWork"
    end

    def additional_type
      metadata.fetch("resourceType", {}).fetch("__content__", nil) ||
      metadata.fetch("resourceType", {}).fetch("resourceTypeGeneral", nil)
    end

    def bibtex_type
      Bolognese::Bibtex::SO_TO_BIB_TRANSLATIONS[type] || "misc"
    end

    def name
      metadata.dig("titles", "title")
    end

    def alternate_name
      parse_attributes(metadata.dig("alternateIdentifiers", "alternateIdentifier"))
    end

    def descriptions
      Array.wrap(metadata.dig("descriptions", "description"))
    end

    def description
      parse_attributes(descriptions)
    end

    def license
      parse_attributes(Array.wrap(metadata.dig("rightsList", "rights")), content: "rightsURI")
    end

    def keywords
      Array.wrap(metadata.dig("subjects", "subject")).join(", ").presence
    end

    def author
      get_authors(metadata.dig("creators", "creator"))
    end

    def editor
      editors = Array.wrap(metadata.dig("contributors", "contributor"))
                     .select { |r| r["contributorType"] == "Editor" }
      get_authors(editors))
    end

    def funder
      f = funder_contributor + funding_reference
      f.length > 1 ? f : f.first
    end

    def funder_contributor
      Array.wrap(metadata.dig("contributors", "contributor")).reduce([]) do |sum, f|
        if f["contributorType"] == "Funder"
          sum << { "@type" => "Organization", "name" => f["contributorName"] }
        else
          sum
        end
      end
    end

    def funding_reference
      Array.wrap(metadata.dig("fundingReferences", "fundingReference")).map do |f|
        funder_id = parse_attributes(f["funderIdentifier"])
        { "@type" => "Organization",
          "@id" => normalize_id(funder_id),
          "name" => f["funderName"] }.compact
      end.uniq
    end

    def version
      metadata.fetch("version", nil)
    end

    def dates
      Array.wrap(metadata.dig("dates", "date"))
    end

    #Accepted Available Copyrighted Collected Created Issued Submitted Updated Valid

    def date(date_type)
      dd = dates.find { |d| d["dateType"] == date_type } || {}
      dd.fetch("__content__", nil)
    end

    def date_created
      date("Created")
    end

    def date_published
      date("Issued") || publication_year
    end

    def date_modified
      date("Updated")
    end

    def publication_year
      metadata.fetch("publicationYear")
    end

    def language
      metadata.fetch("language", nil)
    end

    def spatial_coverage

    end

    def content_size
      metadata.fetch("size", nil)
    end

    def related_identifiers(relation_type)
      Array.wrap(metadata.dig("relatedIdentifiers", "relatedIdentifier"))
        .select { |r| relation_type.split(" ").include?(r["relationType"]) && %w(DOI URL).include?(r["relatedIdentifierType"]) }
        .map do |work|
          { "@type" => "CreativeWork",
            "@id" => normalize_id(work["__content__"]) }
      end.unwrap
    end

    def same_as
      related_identifiers("IsIdenticalTo")
    end

    def is_part_of
      related_identifiers("IsPartOf")
    end

    def has_part
      related_identifiers("HasPart")
    end

    def predecessor_of
      related_identifiers("IsPreviousVersionOf")
    end

    def successor_of
      related_identifiers("IsNewVersionOf")
    end

    def citation
      related_identifiers("Cites IsCitedBy Supplements IsSupplementTo References IsReferencedBy").presence
    end

    def publisher
      { "@type" => "Organization",
        "name" => metadata.fetch("publisher") }
    end

    def container_title
      publisher.fetch("name", nil)
    end

    def provider
      { "@type" => "Organization",
        "name" => "DataCite" }
    end
  end
end