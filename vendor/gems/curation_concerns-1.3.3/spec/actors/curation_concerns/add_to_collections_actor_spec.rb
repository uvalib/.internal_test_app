require 'spec_helper'
describe CurationConcerns::Actors::AddToCollectionActor do
  let(:user) { create(:user) }
  let(:curation_concern) { GenericWork.new }
  let(:attributes) { {} }
  subject do
    CurationConcerns::Actors::ActorStack.new(curation_concern,
                                             user,
                                             [described_class,
                                              CurationConcerns::Actors::GenericWorkActor])
  end
  describe 'the next actor' do
    let(:root_actor) { double }
    before do
      allow(CurationConcerns::Actors::RootActor).to receive(:new).and_return(root_actor)
    end

    let(:attributes) do
      { collection_ids: ['123'], title: ['test'] }
    end

    it 'does not receive the collection_ids' do
      expect(root_actor).to receive(:create).with(title: ['test'])
      subject.create(attributes)
    end
  end

  describe 'create' do
    let(:collection) { create(:collection) }
    let(:attributes) do
      { collection_ids: [collection.id], title: ['test'] }
    end

    it 'adds it to the collection' do
      expect(subject.create(attributes)).to be true
      expect(collection.reload.members).to eq [curation_concern]
    end
  end
end
