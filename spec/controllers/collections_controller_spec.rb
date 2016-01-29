require 'spec_helper'

describe CollectionsController do
  routes { Hydra::Collections::Engine.routes }
  before do
    allow_any_instance_of(User).to receive(:groups).and_return([])
  end

  let(:user) { create(:user) }

  describe '#new' do
    before do
      sign_in user
    end

    it 'assigns @collection' do
      get :new
      expect(assigns(:collection)).to be_kind_of(Collection)
    end
  end

  describe '#create' do
    before do
      sign_in user
    end

    it "creates a Collection" do
      expect {
        post :create, collection: { title: "My First Collection ", description: "The Description\r\n\r\nand more" }
      }.to change { Collection.count }.by(1)
    end

    it "removes blank strings from params before creating Collection" do
      expect {
        post :create, collection: {
          title: "My First Collection ", creator: [""] }
      }.to change { Collection.count }.by(1)
      expect(assigns[:collection].title).to eq("My First Collection ")
      expect(assigns[:collection].creator).to eq([])
    end

    context "with files I can access" do
      let(:asset1) do
        FileSet.create!(title: ["First of the Assets"]) do |fs|
          fs.apply_depositor_metadata(user.user_key)
        end
      end
      let(:asset2) do
        FileSet.create!(title: ["Second of the Assets"], depositor: user.user_key) do |fs|
          fs.apply_depositor_metadata(user.user_key)
        end
      end
      let(:asset3) do
        FileSet.create!(title: ["Third of the Assets"], depositor: 'abc') do |fs|
          fs.apply_depositor_metadata('abc')
        end
      end

      it "creates a collection" do
        expect {
          post :create, collection: { title: "My own Collection", description: "The Description\r\n\r\nand more" },
                        batch_document_ids: [asset1.id, asset2.id, asset3.id]
        }.to change { Collection.count }.by(1)
        collection = assigns(:collection)
        expect(collection.members).to match_array [asset1, asset2]
      end
    end

    it "adds docs to the collection if a batch id is provided and add the collection id to the documents in the collection" do
      asset1 = FileSet.create!(title: ["First of the Assets"]) do |fs|
        fs.apply_depositor_metadata(user.user_key)
      end
      post :create, batch_document_ids: [asset1.id],
                    collection: { title: "My Second Collection ",
                                  description: "The Description\r\n\r\nand more" }
      expect(assigns[:collection].members).to eq [asset1]
      asset_results = ActiveFedora::SolrService.instance.conn.get "select", params: { fq: ["id:\"#{asset1.id}\""], fl: ['id', Solrizer.solr_name(:collection)] }
      expect(asset_results["response"]["numFound"]).to eq 1
      doc = asset_results["response"]["docs"].first
      expect(doc["id"]).to eq asset1.id
      afterupdate = FileSet.find(asset1.id)
      expect(doc[Solrizer.solr_name(:collection)]).to eq afterupdate.to_solr[Solrizer.solr_name(:collection)]
    end
  end

  describe "#update" do
    before { sign_in user }

    let(:collection) do
      Collection.create(title: "Collection Title") do |collection|
        collection.apply_depositor_metadata(user.user_key)
      end
    end

    context "a collections members" do
      let(:asset1) do
        FileSet.create!(title: ["First of the Assets"]) do |fs|
          fs.apply_depositor_metadata(user.user_key)
        end
      end
      let(:asset2) do
        FileSet.create!(title: ["Second of the Assets"], depositor: user.user_key) do |fs|
          fs.apply_depositor_metadata(user.user_key)
        end
      end
      let(:asset3) do
        FileSet.create!(title: ["Third of the Assets"], depositor: 'abc') do |fs|
          fs.apply_depositor_metadata(user.user_key)
        end
      end

      it "sets collection on members" do
        put :update, id: collection,
                     collection: { members: "add" },
                     batch_document_ids: [asset3.id, asset1.id, asset2.id]
        expect(response).to redirect_to routes.url_helpers.collection_path(collection)
        expect(assigns[:collection].members).to match_array [asset2, asset3, asset1]
        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params: { fq: ["id:\"#{asset2.id}\""], fl: ['id', Solrizer.solr_name(:collection)] }
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["id"]).to eq asset2.id
        afterupdate = FileSet.find(asset2.id)
        expect(doc[Solrizer.solr_name(:collection)]).to eq afterupdate.to_solr[Solrizer.solr_name(:collection)]

        put :update, id: collection,
                     collection: { members: "remove" },
                     batch_document_ids: [asset2]
        asset_results = ActiveFedora::SolrService.instance.conn.get "select", params: { fq: ["id:\"#{asset2.id}\""], fl: ['id', Solrizer.solr_name(:collection)] }
        expect(asset_results["response"]["numFound"]).to eq 1
        doc = asset_results["response"]["docs"].first
        expect(doc["id"]).to eq asset2.id
        expect(doc[Solrizer.solr_name(:collection)]).to be_nil
      end
    end

    context "updating a collections metadata" do
      it "saves the metadata" do
        put :update, id: collection, collection: { creator: ['Emily'] }
        collection.reload
        expect(collection.creator).to eq ['Emily']
      end

      it "removes blank strings from params before updating Collection metadata" do
        put :update, id: collection, collection: {
          title: "My Next Collection ", creator: [""] }
        expect(assigns[:collection].title).to eq("My Next Collection ")
        expect(assigns[:collection].creator).to eq([])
      end
    end
  end

  describe "#show" do
    let(:asset1) do
      GenericWork.create!(title: ["First of the Assets"]) { |a| a.apply_depositor_metadata(user) }
    end

    let(:asset2) do
      GenericWork.create!(title: ["Second of the Assets"]) { |a| a.apply_depositor_metadata(user) }
    end

    let(:asset3) do
      GenericWork.create!(title: ["Third of the Assets"]) { |a| a.apply_depositor_metadata(user) }
    end

    let!(:asset4) do
      GenericWork.create!(title: ["Fourth of the Assets"]) { |a| a.apply_depositor_metadata(user) }
    end

    let(:collection) do
      Collection.create(title: "My collection",
                        description: "My incredibly detailed description of the collection",
                        members: [asset1, asset2, asset3]) { |c| c.apply_depositor_metadata(user) }
    end

    context "when signed in" do
      before { sign_in user }

      it "returns the collection and its members" do
        expect(controller).to receive(:add_breadcrumb).with(I18n.t('sufia.dashboard.title'), Sufia::Engine.routes.url_helpers.dashboard_index_path)
        get :show, id: collection
        expect(response).to be_successful
        expect(assigns[:presenter]).to be_kind_of Sufia::CollectionPresenter
        expect(assigns[:presenter].title).to eq collection.title
        expect(assigns[:member_docs].map(&:id)).to match_array [asset1, asset2, asset3].map(&:id)
      end
    end

    context "not signed in" do
      it "does not show me files in the collection" do
        get :show, id: collection
        expect(assigns[:member_docs].count).to eq 0
      end
    end
  end

  describe "#edit" do
    let(:collection) do
      Collection.create(title: "My collection",
                        description: "My incredibly detailed description of the collection") do |c|
        c.apply_depositor_metadata(user)
      end
    end

    before { sign_in user }

    it "is successful" do
      get :edit, id: collection
      expect(response).to be_success
      expect(assigns[:form]).to be_instance_of Sufia::Forms::CollectionForm
      expect(flash[:notice]).to be_nil
    end
  end
end
