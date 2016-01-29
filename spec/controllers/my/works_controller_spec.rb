require 'spec_helper'

describe My::WorksController, type: :controller do
  let(:user) { create(:user) }

  before { sign_in user }

  it "responds with success" do
    get :index
    expect(response).to be_successful
    expect(response).to render_template :index
  end

  it "paginates" do
    3.times { FactoryGirl.create(:work, user: user) }
    get :index, per_page: 2
    expect(assigns[:document_list].length).to eq 2
    get :index, per_page: 2, page: 2
    expect(assigns[:document_list].length).to be >= 1
  end

  describe "upload_set processing" do
    include CurationConcerns::Messages
    let(:upload_set_id) { "upload_set_id" }
    let(:upload_set_id2) { "upload_set_id2" }
    let(:upload_set) { double }

    before do
      allow(upload_set).to receive(:id).and_return(upload_set_id)
      User.batchuser.send_message(user, single_success(upload_set_id, upload_set), success_subject, false)
      User.batchuser.send_message(user, multiple_success(upload_set_id2, [upload_set]), success_subject, false)
      get :index
    end

    it "gets upload_sets that are complete" do
      expect(assigns(:upload_sets).count).to eq(2)
      expect(assigns(:upload_sets)).to include("ss-" + upload_set_id)
      expect(assigns(:upload_sets)).to include("ss-" + upload_set_id2)
    end
  end

  context 'with different types of records' do
    let(:someone_else) { create(:user) }

    let!(:my_collection) do
      Collection.create!(title: 'test collection') do |c|
        c.apply_depositor_metadata(user.user_key)
      end
    end

    let!(:other_collection) { create(:collection) }

    let!(:my_work) { create(:work, user: user) }
    let!(:shared_work) { create(:work, edit_users: [user.user_key], user: someone_else) }
    let!(:unrelated_work) { create(:public_work, user: someone_else) }
    let!(:my_file) { create(:file_set, user: user) }
    let!(:wrong_type) { UploadSet.create }

    it 'shows only the correct records' do
      get :index
      doc_ids = assigns[:document_list].map(&:id)
      expect(doc_ids.count).to eq 1

      # shows works I deposited
      expect(doc_ids).to include(my_work.id)
      # doesn't show collections
      expect(doc_ids).to_not include(my_collection.id)
      # doesn't show shared works
      expect(doc_ids).to_not include(shared_work.id)
      # doesn't show other users' works
      expect(doc_ids).to_not include(unrelated_work.id)
      # doesn't show non-works
      expect(doc_ids).to_not include(wrong_type.id)
      expect(doc_ids).to_not include(my_file.id)

      # Only has collections that I own.
      expect(assigns[:user_collections].map(&:id)).to eq [my_collection.id]
    end
  end # context 'with different types of records'

  it "sets add_files_to_collection when provided in params" do
    get :index, add_files_to_collection: '12345'
    expect(assigns(:add_files_to_collection)).to eql('12345')
  end
end
