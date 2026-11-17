// build: shared
// media.c: a tiny C library (no Lua headers) that LuaJIT's FFI loads directly.
// Built by the test runner as build/libmedia.so:
//   gcc -O2 -shared -fPIC -o build/libmedia.so media.c
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  int width, height;
  uint8_t *data;              /* width * height grey pixels */
} frame_t;

typedef void (*row_cb)(int row, const uint8_t *pixels, int width, void *ud);

static int live_frames = 0;

int media_version(void) { return 10203; }      /* 1.2.3 */
int media_live_frames(void) { return live_frames; }

frame_t *frame_new(int width, int height) {
  frame_t *f = malloc(sizeof *f);
  if (!f) return NULL;
  f->width = width; f->height = height;
  f->data = calloc((size_t)width * height, 1);
  if (!f->data) { free(f); return NULL; }
  live_frames++;
  return f;
}

void frame_free(frame_t *f) {
  if (!f) return;
  free(f->data); free(f);
  live_frames--;
}

void frame_gradient(frame_t *f) {
  for (int y = 0; y < f->height; y++)
    for (int x = 0; x < f->width; x++)
      f->data[y * f->width + x] = (uint8_t)((x + y) & 0xff);
}

uint32_t frame_checksum(const frame_t *f) {   /* FNV-1a over the pixels */
  uint32_t h = 2166136261u;
  for (size_t i = 0; i < (size_t)f->width * f->height; i++) { h ^= f->data[i]; h *= 16777619u; }
  return h;
}

void frame_histogram(const frame_t *f, uint32_t bins[256]) {
  memset(bins, 0, 256 * sizeof bins[0]);
  for (size_t i = 0; i < (size_t)f->width * f->height; i++) bins[f->data[i]]++;
}

void frame_foreach_row(const frame_t *f, row_cb cb, void *ud) {
  for (int y = 0; y < f->height; y++) cb(y, f->data + (size_t)y * f->width, f->width, ud);
}
