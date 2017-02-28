module Bolognese
  class SchemaOrg < Metadata

    SO_TO_DC_RELATION_TYPES = {
      "citation" => "References",
      "sameAs" => "IsIdenticalTo",
      "isPartOf" => "IsPartOf",
      "hasPart" => "HasPart",
      "isPredecessor" => "IsPreviousVersionOf",
      "isSuccessor" => "IsNewVersionOf"
    }

    def initialize(id: nil, string: nil)
      id = normalize_id(id) if id.present?

      if string.present?
        @raw = string
      elsif id.present?
        response = Maremma.get(id)
        doc = Nokogiri::XML(response.body.fetch("data", nil))
        @raw = doc.at_xpath('//script[@type="application/ld+json"]')
      end
    end

    def metadata
      @metadata ||= raw.present? ? Maremma.from_json(raw) : {}
    end

    def exists?
      metadata.present?
    end

    def valid?
      true
    end

    def doi
      doi_from_url(id)
    end

    def id
      normalize_id(metadata.fetch("@id", nil))
    end

    def url
      normalize_id(metadata.fetch("url", nil))
    end

    def resource_type_general
      SO_TO_DC_TRANSLATIONS[type]
    end

    def type
      metadata.fetch("@type", nil)
    end

    def additional_type
      metadata.fetch("additionalType", nil)
    end

    def bibtex_type
      Bolognese::Bibtex::SO_TO_BIB_TRANSLATIONS[type] || "misc"
    end

    def name
      metadata.fetch("name", nil)
    end

    def alternate_name
      metadata.fetch("alternateName", nil)
    end

    def author
      authors = from_schema_org(Array.wrap(metadata.fetch("author", nil)))
      get_authors(authors)
    end

    def editor
      editors = from_schema_org(Array.wrap(metadata.fetch("editor", nil)))
      get_authors(editors)
    end

    def description
      metadata.fetch("description", nil)
    end

    def license
      metadata.fetch("license", nil)
    end

    def version
      metadata.fetch("version", nil)
    end

    def keywords
      metadata.fetch("keywords", nil)
    end

    def date_created
      metadata.fetch("dateCreated", nil)
    end

    def date_published
      metadata.fetch("datePublished", nil)
    end

    def date_modified
      metadata.fetch("dateModified", nil)
    end

    def related_identifier
      Array.wrap(is_identical_to) +
      Array.wrap(is_part_of) +
      Array.wrap(has_part) +
      Array.wrap(is_previous_version_of) +
      Array.wrap(is_new_version_of) +
      Array.wrap(references)
    end

    def get_related_identifier(relation_type: nil)
      normalize_ids(metadata.fetch(relation_type, nil), SO_TO_DC_RELATION_TYPES[relation_type])
    end

    def is_identical_to
      get_related_identifier(relation_type: "sameAs")
    end

    def is_part_of
      get_related_identifier(relation_type: "isPartOf")
    end

    def has_part
      get_related_identifier(relation_type: "hasPart")
    end

    def is_previous_version_of
      get_related_identifier(relation_type: "isPredecessor")
    end

    def is_new_version_of
      get_related_identifier(relation_type: "isSuccessor")
    end

    def references
      get_related_identifier(relation_type: "citation")
    end

    def publisher
      metadata.dig("publisher", "name")
    end

    def container_title
      if publisher.is_a?(Hash)
        publisher.fetch("name", nil)
      elsif publisher.is_a?(String)
        publisher
      end
    end

    def provider
      metadata.fetch("provider", nil)
    end
  end
end
