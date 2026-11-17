#include "frame.hpp"

#include <algorithm>
#include <cstdio>

Frame Frame::test_pattern(int w, int h, int t) {
  Frame f(w, h);
  for (int y = 0; y < h; ++y)
    for (int x = 0; x < w; ++x) f.at(x, y) = static_cast<std::uint8_t>(x * 255 / (w - 1) / 2);
  for (int y = h / 4; y < h * 3 / 4; ++y)
    for (int x = w / 2 + t; x < w * 3 / 4 + t && x < w; ++x) f.at(x, y) = 230;   // a bright box
  for (int i = 0; i < std::min(w, h); ++i) f.at((i + t) % w, i) = 255;   // a diagonal line
  return f;
}

std::uint32_t Frame::checksum() const {
  std::uint32_t h = 2166136261u;
  for (auto p : pixels) { h ^= p; h *= 16777619u; }
  return h;
}

std::string Frame::stats() const {
  auto [lo, hi] = std::minmax_element(pixels.begin(), pixels.end());
  double sum = 0;
  for (auto p : pixels) sum += p;
  char buf[96];
  std::snprintf(buf, sizeof buf, "min=%3d max=%3d mean=%6.2f fnv=%08x", *lo, *hi,
                sum / pixels.size(), checksum());
  return buf;
}

std::string Frame::ascii(int cols) const {
  static const char ramp[] = " .:-=+*#%@";
  const int step = std::max(1, width / cols), rows = height / (step * 2);
  std::string out;
  for (int r = 0; r < rows; ++r) {
    out += "  |";
    for (int c = 0; c < cols; ++c) {
      int sum = 0, n = 0;                    // average a step x 2*step block
      for (int y = r * step * 2; y < (r + 1) * step * 2 && y < height; ++y)
        for (int x = c * step; x < (c + 1) * step && x < width; ++x) { sum += at(x, y); ++n; }
      out += ramp[n ? sum / n * 9 / 255 : 0];
    }
    out += "|\n";
  }
  return out;
}
