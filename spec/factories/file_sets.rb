FactoryGirl.define do
  factory :file_set do
    transient do
      user { FactoryGirl.create(:user) }
    end
    after(:build) do |fs, evaluator|
      fs.apply_depositor_metadata evaluator.user.user_key
    end

    trait :registered do
      read_groups ["registered"]
    end

    factory :public_pdf do
      transient do
        id "fixturepdf"
      end
      initialize_with { new(id: id) }
      read_groups ["public"]
      resource_type ["Dissertation"]
      subject %w(lorem ipsum dolor sit amet)
      title ["fake_document.pdf"]
      mime_type 'application/pdf'
      before(:create) do |fs|
        fs.title = ["Fake PDF Title"]
      end
    end
    factory :public_mp3 do
      transient do
        id "fixturemp3"
      end
      initialize_with { new(id: id) }
      subject %w(consectetur adipisicing elit)
      title ["Test Document MP3.mp3"]
      mime_type 'audio/mpeg'
      read_groups ["public"]
    end
    factory :public_wav do
      transient do
        id "fixturewav"
      end
      initialize_with { new(id: id) }
      resource_type ["Audio", "Dataset"]
      read_groups ["public"]
      title ["Fake Wav File.wav"]
      mime_type 'audio/wav'
      subject %w(sed do eiusmod tempor incididunt ut labore)
    end
  end
end
