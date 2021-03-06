require 'spec_helper'

describe Bolognese::Metadata, vcr: true do
  context "write metadata as crosscite" do
    it "with data citation" do
      input = "10.7554/eLife.01567"
      subject = Bolognese::Metadata.new(input: input, from: "crossref")
      crosscite = JSON.parse(subject.crosscite)
      expect(crosscite.fetch("url")).to eq("https://elifesciences.org/articles/01567")
      expect(crosscite.fetch("resource_type_general")).to eq("Text")
      expect(crosscite.fetch("title")).to eq("Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth")
      expect(crosscite.fetch("references").length).to eq(26)
      expect(crosscite.fetch("references").first).to eq("type"=>"CreativeWork", "id"=>"https://doi.org/10.1038/nature02100", "title"=>"APL regulates vascular tissue identity in Arabidopsis")
      expect(crosscite.fetch("license")).to eq("id"=>"http://creativecommons.org/licenses/by/3.0")
    end

    it "with ORCID ID" do
      input = "https://doi.org/10.1155/2012/291294"
      subject = Bolognese::Metadata.new(input: input, from: "crossref")
      crosscite = JSON.parse(subject.crosscite)
      expect(crosscite.fetch("resource_type_general")).to eq("Text")
      expect(crosscite.fetch("author").count).to eq(7)
      expect(crosscite.fetch("author")[2]).to eq("type"=>"Person", "id"=>"http://orcid.org/0000-0003-2043-4925", "name"=>"Beatriz Hernandez", "givenName"=>"Beatriz", "familyName"=>"Hernandez")
    end

    # it "with editor" do
    #   input = "https://doi.org/10.1371/journal.pone.0000030"
    #   subject = Bolognese::Metadata.new(input: input, from: "crossref")
    #   crosscite = JSON.parse(subject.crosscite)
    #   expect(crosscite["editor"]).to eq("contributorType"=>"Editor", "contributorName"=>"Janbon, Guilhem", "givenName"=>"Guilhem", "familyName"=>"Janbon")
    # end

    it "Crossref DOI" do
      input = fixture_path + "crossref.bib"
      subject = Bolognese::Metadata.new(input: input, from: "bibtex")
      crosscite = JSON.parse(subject.crosscite)
      expect(crosscite.fetch("resource_type_general")).to eq("Text")
      expect(crosscite.fetch("title")).to eq("Automated quantitative histology reveals vascular morphodynamics during Arabidopsis hypocotyl secondary growth")
      expect(crosscite.dig("description", "text")).to start_with("Among various advantages, their small size makes model organisms preferred subjects of investigation.")
      expect(crosscite.fetch("author").count).to eq(5)
      expect(crosscite.fetch("author").first).to eq("type"=>"Person", "name"=>"Martial Sankar", "givenName"=>"Martial", "familyName"=>"Sankar")
    end

    it "BlogPosting Citeproc JSON" do
      input = fixture_path + "citeproc.json"
      subject = Bolognese::Metadata.new(input: input, from: "citeproc")
      expect(subject.valid?).to be true
      crosscite = JSON.parse(subject.crosscite)
      expect(crosscite["resource_type_general"]).to eq("Text")
      expect(crosscite.fetch("title")).to eq("Eating your own Dog Food")
      expect(crosscite.dig("description", "text")).to start_with("Eating your own dog food")
      expect(crosscite.fetch("author")).to eq("type"=>"Person", "name"=>"Martin Fenner", "givenName"=>"Martin", "familyName"=>"Fenner")
    end

    it "rdataone" do
      input = fixture_path + 'codemeta.json'
      subject = Bolognese::Metadata.new(input: input, from: "codemeta")
      crosscite = JSON.parse(subject.crosscite)
      expect(crosscite["title"]).to eq("R Interface to the DataONE REST API")
      expect(crosscite["author"].length).to eq(3)
      expect(crosscite["author"].last).to eq("type"=>"Organization", "name"=>"University Of California, Santa Barbara")
      expect(crosscite["version"]).to eq("2.0.0")
    end

    it "datacite database attributes" do
      input = "https://doi.org/10.5061/DRYAD.8515"
      subject = Bolognese::Metadata.new(input: input, from: "datacite")
      crosscite = JSON.parse(subject.crosscite)
      expect(crosscite.fetch("url")).to eq("http://datadryad.org/resource/doi:10.5061/dryad.8515")
      expect(crosscite.fetch("title")).to eq("Data from: A new malaria agent in African hominids.")
      expect(crosscite.fetch("author").length).to eq(8)
      expect(crosscite.fetch("author").first).to eq("type"=>"Person", "familyName" => "Ollomo", "givenName" => "Benjamin", "name" => "Benjamin Ollomo")
      expect(crosscite.fetch("date_registered")).to eq("2011-02-01T17:32:02Z")
      expect(crosscite.fetch("date_updated")).to eq("2018-03-30T21:47:26Z")
      expect(crosscite.fetch("provider_id")).to eq("CDL")
      expect(crosscite.fetch("client_id")).to eq("CDL.DRYAD")
    end

    it "maremma" do
      input = "https://github.com/datacite/maremma"
      subject = Bolognese::Metadata.new(input: input, from: "codemeta")
      crosscite = JSON.parse(subject.crosscite)
      expect(crosscite.fetch("title")).to eq("Maremma: a Ruby library for simplified network calls")
      expect(crosscite.fetch("author")).to eq("type"=>"Person", "id"=>"http://orcid.org/0000-0003-0077-4738", "name"=>"Martin Fenner", "givenName"=>"Martin", "familyName"=>"Fenner")
    end

    it "with data citation schema.org" do
      input = "https://blog.datacite.org/eating-your-own-dog-food/"
      subject = Bolognese::Metadata.new(input: input, from: "schema_org")
      expect(subject.valid?).to be true
      crosscite = JSON.parse(subject.crosscite)
      expect(crosscite.fetch("title")).to eq("Eating your own Dog Food")
      expect(crosscite.fetch("references").count).to eq(2)
      expect(crosscite.fetch("references").first).to eq("id"=>"https://doi.org/10.5438/0012", "type"=>"CreativeWork")
    end
  end
end
