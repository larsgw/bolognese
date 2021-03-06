module Bolognese
  module Writers
    module BibtexWriter
      def bibtex
        return nil unless valid?

        bib = {
          bibtex_type: bibtex_type.presence || "misc",
          bibtex_key: identifier,
          doi: doi,
          url: b_url,
          author: authors_as_string(author),
          keywords: keywords.present? ? Array.wrap(keywords).map { |k| parse_attributes(k, content: "text", first: true) }.join(", ") : nil,
          language: language,
          title: parse_attributes(title, content: "text", first: true),
          journal: container_title,
          volume: volume,
          issue: issue,
          pages: [first_page, last_page].compact.join("-").presence,
          publisher: publisher,
          year: publication_year
        }.compact
        BibTeX::Entry.new(bib).to_s
      end
    end
  end
end
