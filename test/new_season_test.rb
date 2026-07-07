# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require_relative "../scripts/new_season"

class NewSeasonTest < Minitest::Test
  REPO_ROOT = File.expand_path("..", __dir__)

  def test_index_html_for_small_fixture
    Dir.mktmpdir do |tmp|
      dir = File.join(tmp, "yancya-club-1701-1800")
      FileUtils.mkdir_p(dir)
      %w[001 002 003].each do |n|
        FileUtils.touch(File.join(dir, "yancya-club-1701-1800.#{n}.jpeg"))
      end

      expected = <<~HTML
        <!DOCTYPE html>

        <head>
          <meta charset="utf-8">
          <title>やんちゃクラブ1701-1800</title>
          <link rel="stylesheet" type="text/css" href="../css/yancya-club-thumbnail.css">
        </head>

        <body>
          <div class="container">
            <div><img src="./yancya-club-1701-1800.001.jpeg" alt="やんちゃクラブ #1701 サムネイル" decoding="async" /></div>
            <div><img src="./yancya-club-1701-1800.002.jpeg" alt="やんちゃクラブ #1702 サムネイル" decoding="async" /></div>
            <div><img src="./yancya-club-1701-1800.003.jpeg" alt="やんちゃクラブ #1703 サムネイル" decoding="async" /></div>
          </div>
        </body>
      HTML

      assert_equal expected, NewSeason.index_html(dir)
    end
  end

  def test_index_html_matches_existing_1601_1700_exactly
    dir = File.join(REPO_ROOT, "docs", "yancya-club-1601-1700")
    actual_file = File.read(File.join(dir, "index.html"))

    assert_equal actual_file, NewSeason.index_html(dir)
  end

  def test_images_are_sorted_ascending
    Dir.mktmpdir do |tmp|
      dir = File.join(tmp, "yancya-club-1701-1800")
      FileUtils.mkdir_p(dir)
      %w[010 002 100].each do |n|
        FileUtils.touch(File.join(dir, "yancya-club-1701-1800.#{n}.jpeg"))
      end

      html = NewSeason.index_html(dir)
      positions = %w[002 010 100].map { |n| html.index("1701-1800.#{n}.jpeg") }

      assert_equal positions.sort, positions
    end
  end

  def test_non_jpeg_files_are_ignored
    Dir.mktmpdir do |tmp|
      dir = File.join(tmp, "yancya-club-1701-1800")
      FileUtils.mkdir_p(dir)
      FileUtils.touch(File.join(dir, "yancya-club-1701-1800.001.jpeg"))
      FileUtils.touch(File.join(dir, "index.html"))
      FileUtils.touch(File.join(dir, ".DS_Store"))

      html = NewSeason.index_html(dir)

      assert_includes html, "yancya-club-1701-1800.001.jpeg"
      refute_includes html, "index.html\""
      refute_includes html, ".DS_Store"
    end
  end

  def test_first_three_images_are_eager_and_rest_are_lazy
    Dir.mktmpdir do |tmp|
      dir = File.join(tmp, "yancya-club-1701-1800")
      FileUtils.mkdir_p(dir)
      %w[001 002 003 004 005].each do |n|
        FileUtils.touch(File.join(dir, "yancya-club-1701-1800.#{n}.jpeg"))
      end

      img_lines = NewSeason.index_html(dir).lines.grep(/<img/)

      img_lines.first(3).each do |line|
        refute_includes line, 'loading="lazy"', "先頭3枚は即時読み込みのまま: #{line}"
        assert_includes line, 'decoding="async"'
      end
      img_lines.drop(3).each do |line|
        assert_includes line, 'loading="lazy"', "4枚目以降は遅延読み込み: #{line}"
        assert_includes line, 'decoding="async"'
      end
    end
  end

  def test_alt_numbers_derive_from_filename_serial_and_season_start
    Dir.mktmpdir do |tmp|
      dir = File.join(tmp, "yancya-club-001-100")
      FileUtils.mkdir_p(dir)
      %w[001 050 100].each do |n|
        FileUtils.touch(File.join(dir, "yancya-club-001-100.#{n}.jpeg"))
      end

      html = NewSeason.index_html(dir)

      assert_includes html, 'alt="やんちゃクラブ #1 サムネイル"'
      assert_includes html, 'alt="やんちゃクラブ #50 サムネイル"'
      assert_includes html, 'alt="やんちゃクラブ #100 サムネイル"'
    end
  end

  def test_past_seasons_line_uses_fullwidth_digits
    line = NewSeason.past_seasons_line("yancya-club-1601-1700", "2026/02/02", "2026/05/12")

    assert_equal '<p><a href="yancya-club-1601-1700">やんちゃクラブ１６０１〜１７００</a> (2026/02/02〜2026/05/12)</p>',
                 line
  end

  def test_title_strips_leading_zeros
    Dir.mktmpdir do |tmp|
      dir = File.join(tmp, "yancya-club-001-100")
      FileUtils.mkdir_p(dir)
      FileUtils.touch(File.join(dir, "yancya-club-001-100.001.jpeg"))

      assert_includes NewSeason.index_html(dir), "<title>やんちゃクラブ1-100</title>"
    end
  end

  def test_cli_dry_run_does_not_write
    Dir.mktmpdir do |tmp|
      dir = File.join(tmp, "yancya-club-1701-1800")
      FileUtils.mkdir_p(dir)
      FileUtils.touch(File.join(dir, "yancya-club-1701-1800.001.jpeg"))

      out = `#{RbConfig.ruby} #{File.join(REPO_ROOT, "scripts", "new_season.rb")} --dry-run #{dir} 2026/05/13 2026/08/20`

      assert_equal 0, $?.exitstatus
      refute File.exist?(File.join(dir, "index.html")), "dry-run must not write index.html"
      assert_includes out, "<title>やんちゃクラブ1701-1800</title>"
      assert_includes out, "やんちゃクラブ１７０１〜１８００"
    end
  end

  def test_cli_writes_index_html_and_prints_past_seasons_line
    Dir.mktmpdir do |tmp|
      dir = File.join(tmp, "yancya-club-1701-1800")
      FileUtils.mkdir_p(dir)
      FileUtils.touch(File.join(dir, "yancya-club-1701-1800.001.jpeg"))

      out = `#{RbConfig.ruby} #{File.join(REPO_ROOT, "scripts", "new_season.rb")} #{dir} 2026/05/13 2026/08/20`

      assert_equal 0, $?.exitstatus
      assert File.exist?(File.join(dir, "index.html"))
      assert_includes out, '<p><a href="yancya-club-1701-1800">やんちゃクラブ１７０１〜１８００</a> (2026/05/13〜2026/08/20)</p>'
    end
  end

  def test_cli_fails_on_directory_without_jpegs
    Dir.mktmpdir do |tmp|
      dir = File.join(tmp, "yancya-club-1701-1800")
      FileUtils.mkdir_p(dir)

      `#{RbConfig.ruby} #{File.join(REPO_ROOT, "scripts", "new_season.rb")} --dry-run #{dir} 2026/05/13 2026/08/20 2>/dev/null`

      refute_equal 0, $?.exitstatus
    end
  end
end
