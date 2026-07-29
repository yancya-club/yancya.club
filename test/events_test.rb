# frozen_string_literal: true

require "minitest/autorun"

class EventsTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)
  EVENTS_INDEX = File.join(REPO_ROOT, "docs", "events", "index.html")
  TEMPLATE_INDEX = File.join(REPO_ROOT, "docs", "events", "_template", "index.html")

  def test_events_index_has_no_planned_events_placeholder_after_heading
    html = File.read(EVENTS_INDEX)
    heading = "<h2>やんちゃクラブイベント予定</h2>"

    assert_includes html, heading, "予定見出しが見つからない"

    after_heading = html[(html.index(heading) + heading.length)..]
    next_heading_index = after_heading.index("<h2>")
    between = after_heading[0...next_heading_index]

    assert_includes between, "現在告知中のイベントはありません",
                     "予定が無い期間のプレースホルダ文言が無い"
  end

  def test_events_index_completed_events_are_in_descending_date_order
    html = File.read(EVENTS_INDEX)
    section = html[html.index("<h2>実施済みイベント</h2>")..]

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
