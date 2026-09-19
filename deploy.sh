#!/bin/bash
# まつりしんとみマニュアル 公開スクリプト
#   使い方:  ./deploy.sh "変更内容のメモ"
#   例:      ./deploy.sh "D-1グランプリに変更"
set -e
cd "$(dirname "$0")"

MSG="${1:-マニュアル更新}"

# 1) 変更があるか確認
if [ -z "$(git status --porcelain)" ]; then
  echo "変更はありません。公開サイトは既に最新です。"
  exit 0
fi

echo "▼ 今回アップロードする内容"
git status --short
echo

# 2) HTMLのタグ構造を簡易チェック（壊れたまま公開するのを防ぐ）
if [ -f index.html ]; then
  python3 - <<'PY'
import html.parser, sys
class P(html.parser.HTMLParser):
    def __init__(s):
        super().__init__(); s.stack=[]; s.err=[]
        s.void={'br','img','meta','link','input','hr','source','area','base','col','embed','param','track','wbr'}
    def handle_starttag(s,t,a):
        if t not in s.void: s.stack.append(t)
    def handle_endtag(s,t):
        if t in s.void: return
        if not s.stack: s.err.append(f"余分な </{t}>"); return
        if s.stack[-1]!=t:
            s.err.append(f"不一致 </{t}> vs <{s.stack[-1]}>")
            for i in range(len(s.stack)-1,-1,-1):
                if s.stack[i]==t: del s.stack[i:]; break
        else: s.stack.pop()
p=P(); p.feed(open('index.html',encoding='utf-8').read())
if p.stack or p.err:
    print("★ index.html のタグ構造に問題があります。公開を中止しました。")
    print("  未閉じ:", p.stack, "/ エラー:", p.err[:5]); sys.exit(1)
print("✓ index.html タグ構造チェック OK")
PY
fi

# 3) 反映
git add -A
git commit -m "$MSG"
git push origin master

echo
echo "✅ アップロード完了: $MSG"
echo "   1〜2分後に反映されます → https://kashu19921118-alt.github.io/matsuri-shintomi/"
