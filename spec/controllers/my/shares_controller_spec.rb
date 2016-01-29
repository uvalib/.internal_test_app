require 'spec_helper'

describe My::SharesController, type: :controller do
  describe "logged in user" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    describe "#index" do
      let(:other_user) { create(:user) }

      let!(:my_file) { create(:file_set, user: user) }
      let!(:unshared_file) { create(:file_set, user: other_user) }

      let!(:shared_with_me) { create(:file_set).tap do |r|
        r.apply_depositor_metadata other_user
        r.edit_users += [user.user_key]
        r.save!
      end
      }

      let!(:read_shared_with_me) do
        create(:file_set, user: other_user).tap do |r|
          r.read_users += [user.user_key]
          r.save!
        end
      end

      let!(:shared_with_someone_else) do
        create(:file_set).tap do |r|
          r.apply_depositor_metadata user
          r.edit_users += [other_user.user_key]
          r.save!
        end
      end

      let!(:my_collection) do
        Collection.new(title: "My collection") do |c|
          c.apply_depositor_metadata(user.user_key)
          c.save!
        end
      end

      it "responds with success" do
        get :index
        expect(response).to be_successful
      end

      it "paginates" do
        create(:file_set).tap do |r|
          r.apply_depositor_metadata other_user
          r.edit_users += [user.user_key]
          r.save!
        end
        create(:file_set).tap do |r|
          r.apply_depositor_metadata other_user
          r.edit_users += [user.user_key]
          r.save!
        end
        get :index, per_page: 2
        expect(assigns[:document_list].length).to eq 2
        get :index, per_page: 2, page: 2
        expect(assigns[:document_list].length).to be >= 1
      end

      it "shows the correct documents" do
        get :index
        # shows documents shared with me
        expect(assigns[:document_list].map(&:id)).to include(shared_with_me.id)
        # doesn't show normal files
        expect(assigns[:document_list].map(&:id)).to_not include(my_file.id)
        expect(assigns[:document_list].map(&:id)).to_not include(unshared_file.id)
        # doesn't show files shared with other users
        expect(assigns[:document_list].map(&:id)).to_not include(shared_with_someone_else.id)
        # doesn't show my collections
        expect(assigns[:document_list].map(&:id)).to_not include my_collection.id
        # doesn't show files I can see but have no edit access
        expect(assigns[:document_list].map(&:id)).to_not include read_shared_with_me.id
      end
    end
  end
end
