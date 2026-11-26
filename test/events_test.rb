# frozen_string_literal: true

require "minitest/autorun"

class EventsTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  EVENTS_INDEX = File.join(REPO_ROOT, "docs", "events", "index.html")
  TEMPLATE_INDEX = File.join(REPO_ROOT, "docs", "events", "_template", "index.html")

  PLACEHOLDER = "現在告知中のイベントはありません"

  def planned_section
    html = File.read(EVENTS_INDEX)
    heading = "<h2>やんちゃクラブイベント予定</h2>"

    assert_includes html, heading, "予定見出しが見つからない"

    after_heading = html[(html.index(heading) + heading.length)..]
    after_heading[0...after_heading.index("<h2>")]
  end

  def completed_section
    html = File.read(EVENTS_INDEX)
    heading = "<h2>実施済みイベント</h2>"

    assert_includes html, heading, "実施済み見出しが見つからない"

    html[html.index(heading)..]
  end

  def test_events_index_planned_section_shows_links_or_placeholder_exclusively
    section = planned_section
    has_links = section.include?("<a ")

    if has_links
      refute_includes section, PLACEHOLDER, "告知中イベントがあるのにプレースホルダが残っている"
    else
      assert_includes section, PLACEHOLDER, "予定が無い期間のプレースホルダ文言が無い"
    end
  end

  def test_events_index_links_to_birthday_2026
    assert_includes planned_section, %(href="birthday/2026"), "生誕2026 へのリンクが無い"
  end

  def test_birthday_2026_page_has_image_and_details
    dir = File.join(REPO_ROOT, "docs", "events", "birthday", "2026")
    html = File.read(File.join(dir, "index.html"))

    assert File.exist?(File.join(dir, "image.webp")), "image.webp が無い"
    assert_includes html, %(src="./image.webp"), "index.html が image.webp を参照していない"
    assert_includes html, "yancya 生誕 2026"
    assert_includes html, "2026年12月19日（土）18:00"
    assert_includes html, "2026年12月19日（土）23:00"
    assert_includes html, "1,500円＋1ドリンク"
    assert_includes html, "https://calendar.google.com/calendar/render?action=TEMPLATE"
    assert_includes html, "dates=20261219T090000Z/20261219T140000Z"
  end

  def test_events_index_links_to_fes_001_as_completed
    refute_includes planned_section, %(href="fes/001"), "開催済みのやんちゃフェス Vol.001 が予定に残っている"
    assert_includes completed_section, %(href="fes/001"), "実施済みイベントにやんちゃフェス Vol.001 が無い"
  end

  def test_fes_001_page_has_flyer_and_access_images
    dir = File.join(REPO_ROOT, "docs", "events", "fes", "001")
    html = File.read(File.join(dir, "index.html"))

    %w[flyer.png access.png].each do |name|
      assert File.exist?(File.join(dir, name)), "#{name} が無い"
      assert_includes html, %(src="#{name}"), "index.html が #{name} を参照していない"
    end
  end

  def test_events_index_completed_events_are_in_descending_date_order
    section = completed_section

    dates = section.scan(%r{href="(?:birthday|bounen|coffee|mujinto)/(\d{4})}).flatten.map(&:to_i)

    assert_operator dates.length, :>, 0, "実施済みイベントの年が抽出できない"
    assert_equal dates.sort.reverse, dates, "実施済みイベントが開催日降順になっていない"
  end

  def test_template_exists_with_required_sections
    assert File.exist?(TEMPLATE_INDEX), "docs/events/_template/index.html が無い"

    html = File.read(TEMPLATE_INDEX)

    assert_includes html, "<h1>"
    assert_includes html, "募集要項"
    assert_includes html, "開始"
    assert_includes html, "終了"
    assert_includes html, "場所"
  end

  def test_template_has_no_index_conflicting_metadata
    html = File.read(TEMPLATE_INDEX)

    refute_includes html, "yancya 生誕", "テンプレートに実イベント固有の文言が残っている"
  end
end
