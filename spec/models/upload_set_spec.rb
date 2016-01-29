require 'spec_helper'

describe UploadSet do
  let(:user) { create(:user) }
  let(:upload_set) { described_class.create(title: ["test collection"]) }
  subject { upload_set }

  it "has dc metadata" do
    expect(subject.title).to eq ["test collection"]
  end

  it "responds to #works" do
    expect(subject).to respond_to(:works)
  end

  it "supports to_solr" do
    expect(subject.to_solr).to_not be_nil
    expect(subject.to_solr["upload_set__title_t"]).to be_nil
  end

  describe "find_or_create" do
    before do
      allow(described_class).to receive(:acquire_lock_for).and_yield if $in_travis
    end
    describe "when the object exists" do
      let!(:upload_set) { described_class.create(title: ["test collection"]) }
      it "finds upload_set instead of creating" do
        expect(described_class).to_not receive(:create)
        described_class.find_or_create(subject.id)
      end
    end
    describe "when the object does not exist" do
      it "creates a new UploadSet" do
        expect { described_class.find("upload_set-123") }.to raise_error(ActiveFedora::ObjectNotFoundError)
        expect(described_class).to receive(:create).once.and_return("the upload_set")
        expect(described_class.find_or_create("upload_set-123")).to eq "the upload_set"
      end
    end
  end
end
