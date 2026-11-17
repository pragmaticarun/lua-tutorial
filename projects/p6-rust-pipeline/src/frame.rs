//! A grayscale frame, byte for byte the same as the C++ host's (Project 5),
//! so both hosts print identical statistics for identical scripts.

#[derive(Clone)]
pub struct Frame {
    pub width: usize,
    pub height: usize,
    pub pixels: Vec<u8>,
}

impl Frame {
    pub fn new(width: usize, height: usize) -> Self {
        Frame { width, height, pixels: vec![0; width * height] }
    }

    pub fn at(&self, x: usize, y: usize) -> u8 {
        self.pixels[y * self.width + x]
    }

    pub fn set(&mut self, x: usize, y: usize, v: u8) {
        self.pixels[y * self.width + x] = v;
    }

    /// gradient, a bright box and a diagonal line; `t` moves the last two
    pub fn test_pattern(w: usize, h: usize, t: usize) -> Self {
        let mut f = Frame::new(w, h);
        for y in 0..h {
            for x in 0..w {
                f.set(x, y, (x * 255 / (w - 1) / 2) as u8);
            }
        }
        for y in h / 4..h * 3 / 4 {
            for x in (w / 2 + t)..(w * 3 / 4 + t).min(w) {
                f.set(x, y, 230);
            }
        }
        for i in 0..w.min(h) {
            f.set((i + t) % w, i, 255);
        }
        f
    }

    pub fn checksum(&self) -> u32 {
        self.pixels.iter().fold(2166136261u32, |h, &p| (h ^ p as u32).wrapping_mul(16777619))
    }

    pub fn stats(&self) -> String {
        let lo = self.pixels.iter().min().unwrap();
        let hi = self.pixels.iter().max().unwrap();
        let sum: f64 = self.pixels.iter().map(|&p| p as f64).sum();
        format!("min={:3} max={:3} mean={:6.2} fnv={:08x}", lo, hi,
                sum / self.pixels.len() as f64, self.checksum())
    }

    pub fn ascii(&self, cols: usize) -> String {
        const RAMP: &[u8] = b" .:-=+*#%@";
        let step = (self.width / cols).max(1);
        let rows = self.height / (step * 2);
        let mut out = String::new();
        for r in 0..rows {
            out.push_str("  |");
            for c in 0..cols {
                let (mut sum, mut n) = (0usize, 0usize);
                for y in r * step * 2..((r + 1) * step * 2).min(self.height) {
                    for x in c * step..((c + 1) * step).min(self.width) {
                        sum += self.at(x, y) as usize;
                        n += 1;
                    }
                }
                out.push(RAMP[if n > 0 { sum / n * 9 / 255 } else { 0 }] as char);
            }
            out.push_str("|\n");
        }
        out
    }
}
