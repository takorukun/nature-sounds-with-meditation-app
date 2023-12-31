require 'rails_helper'

RSpec.describe "Top_page", type: :system, js: true do
  let(:user) { create(:user) }
  let!(:videos) do
    [
      create(:video, title: "Sample Video 1", user: user),
      create(:video, title: "Sample Video 2", user: user),
      create(:video, title: "Sample Video 3", user: user),
    ]
  end
  let!(:tags) { ["焚き火", "森林", "洞窟"] }
  let(:mocked_response) do
    {
      items: [
        {
          snippet: {
            title: "Sample Video Title",
            publishedAt: "2023-10-22T00:00:00Z",
            thumbnails: {
              maxres: {
                url: "https://sample/maxres_thumbnail.jpg",
              },
            },
          },
          statistics: {
            viewCount: "1000",
          },
        },
      ],
    }
  end

  def resize_window_to_mobile
    page.driver.browser.manage.window.resize_to(360, 640)
  end

  def resize_window_to_desktop
    page.driver.browser.manage.window.resize_to(1024, 768)
  end

  before do
    youtube_api_key = ENV['YOUTUBE_API_KEY']

    stub_request(:get, "https://youtube.googleapis.com/youtube/v3/videos?id=test_video_id&key=#{youtube_api_key}&part=snippet,statistics").
      with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip,deflate',
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Date' => /.*/,
          'X-Goog-Api-Client' => 'gl-ruby/3.0.5 gdcl/1.11.1',
        }
      ).
      to_return(status: 200, body: mocked_response.to_json, headers: { 'Content-Type' => 'application/json' })

    videos.each_with_index do |video, index|
      video.tag_list.add(tags[index])
      video.save
    end

    visit root_path
  end

  it "allows searching by title" do
    fill_in 'q[title_cont]', with: videos.first.title
    click_on '検索'
    expect(page).to have_content(videos.first.title)
    expect(page).not_to have_content(videos.second.title)
    expect(page).not_to have_content(videos.third.title)
  end

  it "allows filtering by tags" do
    check "tag_0"
    click_on '検索'
    expect(page).to have_content(videos.first.title)
    expect(page).not_to have_content(videos.second.title)
    expect(page).not_to have_content(videos.third.title)
  end

  it "displays searched tags above the results" do
    check "tag_0"
    click_on '検索'
    expect(page).to have_content("検索されたタグ: 焚き火")
  end

  it "displays video details correctly" do
    click_on '検索'
    videos.each_with_index do |video, index|
      within all('.video-item')[index] do
        expect(page).to have_css("iframe[src*='#{video.youtube_video_id}']")
        title_element = find('h3 .text-xl')
        expect(title_element).to have_content(video.title)
        expect(page).to have_link(video.title + "を再生する", href: video_path(video))

        video.tag_list.each do |tag|
          expect(page).to have_content(tag)
        end
      end
    end
  end

  it "home button has root_path" do
    expect(page).to have_current_path(root_path)
  end

  context 'when not logged in' do
    before do
      visit root_path
    end

    describe "on desktop view" do
      before { resize_window_to_desktop }

      it "has expected contents" do
        expect(page).to have_content("ログイン")
        expect(page).to have_content("新規登録")
      end
    end

    describe "on mobile view" do
      before { resize_window_to_mobile }

      it "shows the dropdown" do
        expect(page).to have_selector('.dropdown')
      end

      it "has login and signup options in the dropdown" do
        find('.dropdown').click
        expect(page).to have_selector('.dropdown', text: 'ログイン')
        expect(page).to have_selector('.dropdown', text: '新規登録')
      end
    end

    it "navigates to login page when login button is clicked" do
      click_on 'ログイン'
      sleep 2
      expect(current_path).to eq new_user_session_path
    end

    it "navigates to signup page when signup button is clicked" do
      click_on '新規登録'
      sleep 2
      expect(current_path).to eq new_user_registration_path
    end
  end

  context 'when logged in' do
    before do
      sign_in user
      visit root_path
    end

    describe "on desktop view" do
      before { resize_window_to_desktop }

      it "has expected contents" do
        expect(page).to have_css("img[src*='default_user_icon_640']")
        expect(page).to have_content("プロフィール")
        expect(page).to have_content("ログアウト")
        expect(page).to have_content("動画を共有する")
      end

      it "have meditate_meditations_path and display サウンドを選択し、瞑想を始めましょう。" do
        click_on '検索'
        videos.each_with_index do |video, index|
          within all('.video-item')[index] do
            expect(page).to have_link("瞑想を始める", href: meditate_meditations_path(video_id: video.id))
          end
        end
      end

      it "navigates to profile page when profile button is clicked" do
        click_on 'プロフィール'
        sleep 2
        expect(current_path).to eq user_path(user)
      end

      it "logs out when logout button is clicked" do
        click_on 'ログアウト'
        expect(current_path).to eq root_path
        expect(page).to have_content("ログイン")
        expect(page).to have_content("新規登録")
      end

      it "navigates to profile page when profile button is clicked" do
        click_on '動画を共有する'

        sleep 2

        expect(current_path).to eq new_video_path
        expect(page).to have_content("動画URL")
        expect(page).to have_content("動画タイトル")
        expect(page).to have_content("動画説明")
        expect(page).to have_button("投稿")
        expect(page).to have_content("戻る")

        tags.each do |tag|
          expect(page).to have_content(tag)
        end
      end

      context 'when set the avatar image' do
        before do
          sign_in user
          allow_any_instance_of(ApplicationHelper).to receive(:user_avatar_url).and_return('http://example.com/fake_avatar_url')
          visit root_path
        end

        it 'displays the avatar image' do
          expect(page).to have_css("img[src='http://example.com/fake_avatar_url']")
        end
      end
    end

    describe "on mobile view" do
      before { resize_window_to_mobile }

      it "shows the dropdown" do
        expect(page).to have_selector('.dropdown')
      end

      it "has profile and logout options in the dropdown" do
        find('.dropdown').click
        expect(page).to have_css("img[src*='default_user_icon_640']")
        expect(page).to have_selector('.dropdown', text: 'プロフィール')
        expect(page).to have_selector('.dropdown', text: 'ログアウト')
        expect(page).to have_selector('.dropdown', text: '動画を共有する')
      end
    end
  end
end
