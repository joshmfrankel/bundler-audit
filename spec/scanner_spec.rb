require 'spec_helper'
require 'bundler/audit/scanner'

describe Scanner do
  describe "#scan" do
    let(:bundle)    { 'unpatched_gems' }
    let(:directory) { File.join('spec','bundle',bundle) }

    subject { described_class.new(directory) }

    it "should yield results" do
      results = []

      subject.scan { |result| results << result }

      expect(results).not_to be_empty
    end

    context "when not called with a block" do
      it "should return an Enumerator" do
        expect(subject.scan).to be_kind_of(Enumerable)
      end
    end
  end

  context "when auditing a bundle with unpatched gems" do
    let(:bundle)    { 'unpatched_gems' }
    let(:directory) { File.join('spec','bundle',bundle) }
    let(:scanner)  { described_class.new(directory)    }

    subject { scanner.scan.to_a }

    it "should match unpatched gems to their advisories" do
      ids = subject.map { |result| result.advisory.id }
      expect(ids).to include('CVE-2013-0155')
      expect(subject.all? { |result|
        result.advisory.vulnerable?(result.gem.version)
      }).to be_truthy
    end

    context "when the :ignore option is given" do
      subject { scanner.scan(:ignore => ['CVE-2013-0155']) }

      it "should ignore the specified advisories" do
        ids = subject.map { |result| result.advisory.id }
        expect(ids).not_to include('CVE-2013-0155')
      end
    end

    context "when the :filter option is given" do
      subject { scanner.scan(filter: ['high']) }

      it "should return only filtered criticalities" do
        criticalities = subject.map { |result| result.advisory.criticality }
        expect(criticalities).not_to include(:medium, :low, nil)
        expect(criticalities).to include(:high)
      end
    end
  end

  context "when auditing a bundle with insecure sources" do
    let(:bundle)    { 'insecure_sources' }
    let(:directory) { File.join('spec','bundle',bundle) }
    let(:scanner)   { described_class.new(directory)    }

    subject { scanner.scan.to_a }

    it "should match unpatched gems to their advisories" do
      expect(subject[0].source).to eq('git://github.com/rails/jquery-rails.git')
      expect(subject[1].source).to eq('http://rubygems.org/')
    end
  end

  context "when auditing a secure bundle" do
    let(:bundle)    { 'secure' }
    let(:directory) { File.join('spec','bundle',bundle) }
    let(:scanner)   { described_class.new(directory)    }

    subject { scanner.scan.to_a }

    it "should print nothing when everything is fine" do
      expect(subject).to be_empty
    end
  end
end
