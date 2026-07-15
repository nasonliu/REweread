#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$ROOT_DIR/downloads/fonts}"
STAGE_DIR="$DOWNLOAD_DIR/stage"
MOVE_HOST="${MOVE_HOST:-root@10.11.99.1}"
REMOTE_FONT_DIR="${REMOTE_FONT_DIR:-/home/root/.local/share/fonts}"

MICROHEI_URL="https://downloads.sourceforge.net/project/wqy/wqy-microhei/0.2.0-beta/wqy-microhei-0.2.0-beta.tar.gz"
ZENHEI_URL="https://downloads.sourceforge.net/project/wqy/wqy-zenhei/0.9.45%20%28Fighting-state%20RC1%29/wqy-zenhei-0.9.45.tar.gz"
LXGW_WENKAI_COMMIT="061398910b550e1c68a302b4641aaf0e20bbf3ae"
LXGW_WENKAI_URL="https://raw.githubusercontent.com/lxgw/LxgwWenKai/$LXGW_WENKAI_COMMIT/fonts/TTF/LXGWWenKai-Regular.ttf"
SOURCE_HAN_SANS_COMMIT="a4f7cf94edfb9d7ffbdfc4841de276358bd7e0f2"
SOURCE_HAN_SERIF_COMMIT="7889f11bf31170b5d092a083b357c8c8130f89e0"
SOURCE_HAN_SANS_URL="https://github.com/adobe-fonts/source-han-sans/raw/$SOURCE_HAN_SANS_COMMIT/OTF/SimplifiedChinese/SourceHanSansSC-Regular.otf"
SOURCE_HAN_SERIF_URL="https://github.com/adobe-fonts/source-han-serif/raw/$SOURCE_HAN_SERIF_COMMIT/OTF/SimplifiedChinese/SourceHanSerifSC-Regular.otf"
CHILL_KAI_URL="https://github.com/Warren2060/Chillkai/releases/download/v2.000/ChillKai.zip"
CHILL_HUOSONG_URL="https://github.com/Warren2060/ChillMovableType/releases/download/HuoSongv1.000/ChillHuoSong_F.zip"
GOOGLE_FONTS_COMMIT="ec0464b978de222073645d6d3366f3fdf03376d8"
MA_SHAN_ZHENG_URL="https://raw.githubusercontent.com/google/fonts/$GOOGLE_FONTS_COMMIT/ofl/mashanzheng/MaShanZheng-Regular.ttf"
LIU_JIAN_MAO_CAO_URL="https://raw.githubusercontent.com/google/fonts/$GOOGLE_FONTS_COMMIT/ofl/liujianmaocao/LiuJianMaoCao-Regular.ttf"
ZHI_MANG_XING_URL="https://raw.githubusercontent.com/google/fonts/$GOOGLE_FONTS_COMMIT/ofl/zhimangxing/ZhiMangXing-Regular.ttf"
LONG_CANG_URL="https://raw.githubusercontent.com/google/fonts/$GOOGLE_FONTS_COMMIT/ofl/longcang/LongCang-Regular.ttf"
ZCOOL_KUAILE_URL="https://raw.githubusercontent.com/google/fonts/$GOOGLE_FONTS_COMMIT/ofl/zcoolkuaile/ZCOOLKuaiLe-Regular.ttf"
MICROHEI_SHA256="2802ac8023aa36a66ea6e7445854e3a078d377ffff42169341bd237871f7213e"
ZENHEI_SHA256="e4b7e306475bf9427d1757578f0e4528930c84c44eaa3f167d4c42f110ee75d6"
LXGW_WENKAI_SHA256="39ad71264b588165b469e35e6afb162a378dacd1f95348160240ba9038ac3009"
SOURCE_HAN_SANS_SHA256="f1d8611151880c6c336aabeac4640ef434fa13cbfbf1ffe82d0a71b2a5637256"
SOURCE_HAN_SERIF_SHA256="78aa7a328fd974df2d688c8a9fd74a33d8334dfa84ab24d9d11efb2ffc464117"
CHILL_KAI_SHA256="b2224fb5443ca933a5654f74c51b1c57724f9ee84e1fc5dbbd09a0201f3e86a8"
CHILL_HUOSONG_SHA256="e3187519d212f3f18db192cbb4e867feb124b14e05d0a08647315a85fd187bc1"
CHILL_KAI_FONT_SHA256="33a4f5120f80e45c2188445fe710e4cdbf7c7ed6d89fb901a188f164b6c407fc"
CHILL_HUOSONG_FONT_SHA256="6f9c500239c812fe5ca02051d2b61171f32b62badc8cd31791bc9f1d2faece8b"
MA_SHAN_ZHENG_SHA256="b844c59bf20bf530e41c20d6ff12b383b23a2e553b9b68cc89f070869213155d"
LIU_JIAN_MAO_CAO_SHA256="cab396b91a5b7c0b4005a35891180d06e6751f5ac261fe680aec65c1ae209033"
ZHI_MANG_XING_SHA256="644e0cae9b40f0b10ab729a01bd32032e3973bac22be3dccae01bf6ae7fde969"
LONG_CANG_SHA256="e5bf2c3f24ef2327c6f136d8f73e2f9dfdf44896fdbeb35a9515f44777bb91bc"
ZCOOL_KUAILE_SHA256="812a6fc1fe54b6d73a419245c32dfeba8aa33104d5be90d1cf6af082007cb71d"

mkdir -p "$DOWNLOAD_DIR" "$STAGE_DIR"

download_font() {
  local url="$1"
  local archive="$DOWNLOAD_DIR/${url##*/}"
  if [[ ! -s "$archive" ]]; then
    curl -fL --retry 3 --retry-delay 2 "$url" -o "$archive"
  fi
  tar -xzf "$archive" -C "$STAGE_DIR"
}

download_file_font() {
  local url="$1"
  local target="$2"
  mkdir -p "$(dirname "$target")"
  if [[ ! -s "$target" ]]; then
    curl -fL --retry 3 --retry-delay 2 "$url" -o "$target"
  fi
}

extract_zip_font() {
  local archive="$1"
  local zip_member="$2"
  local target="$3"
  local extract_dir
  extract_dir="$(dirname "$target")"
  mkdir -p "$extract_dir"
  unzip -jo "$archive" "$zip_member" -d "$extract_dir" >/dev/null
  local extracted="$extract_dir/${zip_member##*/}"
  if [[ "$extracted" != "$target" ]]; then
    mv -f "$extracted" "$target"
  fi
}

verify_sha256() {
  local file="$1"
  local expected="$2"
  local actual
  actual="$(shasum -a 256 "$file" | awk '{print $1}')"
  if [[ "$actual" != "$expected" ]]; then
    echo "Checksum mismatch for $file" >&2
    echo "Expected: $expected" >&2
    echo "Actual:   $actual" >&2
    exit 1
  fi
}

microhei_archive="$DOWNLOAD_DIR/${MICROHEI_URL##*/}"
zenhei_archive="$DOWNLOAD_DIR/${ZENHEI_URL##*/}"
wenkai_file="$STAGE_DIR/lxgw-wenkai/lxgw-wenkai.ttf"
source_han_sans_file="$STAGE_DIR/source-han-sans-sc/source-han-sans-sc.otf"
source_han_serif_file="$STAGE_DIR/source-han-serif-sc/source-han-serif-sc.otf"
chill_kai_archive="$DOWNLOAD_DIR/ChillKai.zip"
chill_huosong_archive="$DOWNLOAD_DIR/ChillHuoSong_F.zip"
chill_kai_file="$STAGE_DIR/chill-kai/chill-kai.ttf"
chill_huosong_file="$STAGE_DIR/chill-huosong/chill-huosong.otf"
ma_shan_zheng_file="$STAGE_DIR/ma-shan-zheng/ma-shan-zheng.ttf"
liu_jian_mao_cao_file="$STAGE_DIR/liu-jian-mao-cao/liu-jian-mao-cao.ttf"
zhi_mang_xing_file="$STAGE_DIR/zhi-mang-xing/zhi-mang-xing.ttf"
long_cang_file="$STAGE_DIR/long-cang/long-cang.ttf"
zcool_kuaile_file="$STAGE_DIR/zcool-kuaile/zcool-kuaile.ttf"

download_font "$MICROHEI_URL"
download_font "$ZENHEI_URL"
download_file_font "$LXGW_WENKAI_URL" "$wenkai_file"
download_file_font "$SOURCE_HAN_SANS_URL" "$source_han_sans_file"
download_file_font "$SOURCE_HAN_SERIF_URL" "$source_han_serif_file"
download_file_font "$CHILL_KAI_URL" "$chill_kai_archive"
download_file_font "$CHILL_HUOSONG_URL" "$chill_huosong_archive"
download_file_font "$MA_SHAN_ZHENG_URL" "$ma_shan_zheng_file"
download_file_font "$LIU_JIAN_MAO_CAO_URL" "$liu_jian_mao_cao_file"
download_file_font "$ZHI_MANG_XING_URL" "$zhi_mang_xing_file"
download_file_font "$LONG_CANG_URL" "$long_cang_file"
download_file_font "$ZCOOL_KUAILE_URL" "$zcool_kuaile_file"

verify_sha256 "$microhei_archive" "$MICROHEI_SHA256"
verify_sha256 "$zenhei_archive" "$ZENHEI_SHA256"
verify_sha256 "$wenkai_file" "$LXGW_WENKAI_SHA256"
verify_sha256 "$source_han_sans_file" "$SOURCE_HAN_SANS_SHA256"
verify_sha256 "$source_han_serif_file" "$SOURCE_HAN_SERIF_SHA256"
verify_sha256 "$chill_kai_archive" "$CHILL_KAI_SHA256"
verify_sha256 "$chill_huosong_archive" "$CHILL_HUOSONG_SHA256"
verify_sha256 "$ma_shan_zheng_file" "$MA_SHAN_ZHENG_SHA256"
verify_sha256 "$liu_jian_mao_cao_file" "$LIU_JIAN_MAO_CAO_SHA256"
verify_sha256 "$zhi_mang_xing_file" "$ZHI_MANG_XING_SHA256"
verify_sha256 "$long_cang_file" "$LONG_CANG_SHA256"
verify_sha256 "$zcool_kuaile_file" "$ZCOOL_KUAILE_SHA256"

extract_zip_font "$chill_kai_archive" "ChillKai/ChillKai.ttf" "$chill_kai_file"
extract_zip_font "$chill_huosong_archive" "ChillHuoSong_F_Regular.otf" "$chill_huosong_file"

verify_sha256 "$chill_kai_file" "$CHILL_KAI_FONT_SHA256"
verify_sha256 "$chill_huosong_file" "$CHILL_HUOSONG_FONT_SHA256"

find "$STAGE_DIR" -type f \( -name '*.ttf' -o -name '*.ttc' -o -name '*.otf' \) -print | sort

if [[ "${INSTALL_TO_MOVE:-0}" == "1" ]]; then
  ssh "$MOVE_HOST" "mkdir -p '$REMOTE_FONT_DIR'"
  rsync -az \
    --include='*/' \
    --include='*.ttf' \
    --include='*.ttc' \
    --include='*.otf' \
    --exclude='*' \
    "$STAGE_DIR/" \
    "$MOVE_HOST:$REMOTE_FONT_DIR/"
  ssh "$MOVE_HOST" "find '$REMOTE_FONT_DIR' -maxdepth 2 -type f \( -name '*.ttf' -o -name '*.ttc' -o -name '*.otf' \) | while IFS= read -r font_path; do sha256sum \"\$font_path\"; done"
fi
