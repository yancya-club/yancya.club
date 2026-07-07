# frozen_string_literal: true

# 新シーズンページ生成スクリプト
#
# 使い方:
#   ruby scripts/new_season.rb [--dry-run] docs/yancya-club-1701-1800 <開始日> <終了日>
#
# 例:
#   ruby scripts/new_season.rb docs/yancya-club-1701-1800 2026/05/13 2026/08/20
#
# 指定ディレクトリ内の jpeg を昇順に列挙して index.html を生成し、
# トップページ「Past seasons」に追記すべき1行を標準出力に表示する。
# --dry-run のときは index.html を書き込まず、生成内容を標準出力に表示する。

module NewSeason
  # ファーストビュー相当。先頭からこの枚数は loading="lazy" を付けず即時読み込みにする
  EAGER_COUNT = 3

  module_function

  def image_files(dir)
    Dir.children(dir).grep(/\.jpeg\z/).sort
  end

  # ディレクトリ名 "yancya-club-1601-1700" から [1601, 1700] を得る
  def season_range(dir)
    base = File.basename(dir)
    m = base.match(/\Ayancya-club-(\d+)-(\d+)\z/)
    raise ArgumentError, "ディレクトリ名が yancya-club-<開始>-<終了> 形式ではない: #{base}" unless m

    [Integer(m[1], 10), Integer(m[2], 10)]
  end

  def index_html(dir)
    from, to = season_range(dir)
    images = image_files(dir)
    raise ArgumentError, "jpeg が1枚も見つからない: #{dir}" if images.empty?

    lines = images.each_with_index.map do |name, i|
      serial = name[/\.(\d+)\.jpeg\z/, 1]
      episode = from + Integer(serial, 10) - 1
      attrs = %(alt="やんちゃクラブ ##{episode} サムネイル")
      attrs += %( loading="lazy") if i >= EAGER_COUNT
      attrs += %( decoding="async")
      %(    <div><img src="./#{name}" #{attrs} /></div>)
    end

    <<~HTML
      <!DOCTYPE html>

      <head>
        <meta charset="utf-8">
        <title>やんちゃクラブ#{from}-#{to}</title>
        <link rel="stylesheet" type="text/css" href="../css/yancya-club-thumbnail.css">
      </head>

      <body>
        <div class="container">
      #{lines.join("\n")}
        </div>
      </body>
    HTML
  end

  def past_seasons_line(dir, start_date, end_date)
    from, to = season_range(dir)
    label = "やんちゃクラブ#{from}〜#{to}".tr("0-9", "０-９")
    %(<p><a href="#{File.basename(dir)}">#{label}</a> (#{start_date}〜#{end_date})</p>)
  end
end

if __FILE__ == $PROGRAM_NAME
  dry_run = ARGV.delete("--dry-run")
  dir, start_date, end_date = ARGV

  unless dir && start_date && end_date
    warn "使い方: ruby scripts/new_season.rb [--dry-run] <シーズンディレクトリ> <開始日> <終了日>"
    warn "例:     ruby scripts/new_season.rb docs/yancya-club-1701-1800 2026/05/13 2026/08/20"
    exit 1
  end

  begin
    html = NewSeason.index_html(dir)
  rescue ArgumentError => e
    warn e.message
    exit 1
  end

  if dry_run
    puts html
  else
    File.write(File.join(dir, "index.html"), html)
    warn "書き込んだ: #{File.join(dir, 'index.html')} (画像 #{NewSeason.image_files(dir).size} 枚)"
  end

  puts "トップページ docs/index.html の「Past seasons」に追記する行:"
  puts NewSeason.past_seasons_line(dir, start_date, end_date)
end
