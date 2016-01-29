require 'spec_helper'

describe CitationsController do
  let(:user) { create(:user) }

  describe "#work" do
    let(:work) { create(:work, user: user) }
    before do
      sign_in user
    end

    it "is successful" do
      get :work, id: work
      expect(response).to be_successful
      expect(assigns(:presenter)).to be_kind_of Sufia::WorkShowPresenter
    end
  end
end
