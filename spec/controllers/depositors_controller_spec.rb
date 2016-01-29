require 'spec_helper'

describe DepositorsController do
  let(:user) { create(:user) }
  let(:grantee) { create(:user) }

  describe "as a logged in user" do
    before do
      sign_in user
    end

    describe "create" do
      it "is successful" do
        expect { post :create, user_id: user.user_key, grantee_id: grantee.user_key, format: 'json' }.to change { ProxyDepositRights.count }.by(1)
        expect(response).to be_success
      end

      it "does not add current user" do
        expect { post :create, user_id: user.user_key, grantee_id: user.user_key, format: 'json' }.to change { ProxyDepositRights.count }.by(0)
        expect(response).to be_success
        expect(response.body).to be_blank
      end
    end

    describe "destroy" do
      before do
        user.can_receive_deposits_from << grantee
      end
      it "is successful" do
        expect { delete :destroy, user_id: user.user_key, id: grantee.user_key, format: 'json' }.to change { ProxyDepositRights.count }.by(-1)
      end
    end
  end

  describe "as a user without access" do
    before do
      sign_in create(:user)
    end
    describe "create" do
      it "is not successful" do
        post :create, user_id: user.user_key, grantee_id: grantee.user_key, format: 'json'
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq "You are not authorized to access this page."
      end
    end
    describe "destroy" do
      it "is not successful" do
        delete :destroy, user_id: user.user_key, id: grantee.user_key, format: 'json'
        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq "You are not authorized to access this page."
      end
    end
  end
end
