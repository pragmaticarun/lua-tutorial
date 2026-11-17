// A grayscale video frame: width x height bytes, row-major.
#pragma once
#include <cstdint>
#include <string>
#include <vector>

struct Frame {
  int width = 0, height = 0;
  std::vector<std::uint8_t> pixels;

  Frame(int w, int h) : width(w), height(h), pixels(static_cast<size_t>(w) * h, 0) {}
  std::uint8_t &at(int x, int y) { return pixels[static_cast<size_t>(y) * width + x]; }
  std::uint8_t at(int x, int y) const { return pixels[static_cast<size_t>(y) * width + x]; }

  static Frame test_pattern(int w, int h, int t = 0);  // gradient, box, diagonal; t moves them
  std::uint32_t checksum() const;            // FNV-1a over the pixels
  std::string stats() const;                 // "min=.. max=.. mean=.. fnv=.."
  std::string ascii(int cols) const;         // a small character preview
};
