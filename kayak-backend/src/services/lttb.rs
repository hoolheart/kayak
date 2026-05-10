//! LTTB (Largest Triangle Three Buckets) downsampling algorithm
//!
//! A visual-preserving time-series data downsampling algorithm.
//!
//! # Algorithm
//! - Divide data into `threshold` buckets
//! - Select points that maximize the triangle area with the previous selected point
//!   and the average of the next bucket
//! - Always preserve first and last points
//!
//! # Boundary Conditions
//! - If N < threshold: return all N points (no downsampling)
//! - If N == threshold: return all N points
//! - If N > threshold: return exactly `threshold` points

/// Standalone LTTB downsampling function
///
/// Delegates to [`LttbDownsampler::downsample`] for the actual implementation.
pub fn lttb_downsample(
    timestamps: &[i64],
    values: &[f64],
    threshold: usize,
) -> (Vec<i64>, Vec<f64>) {
    LttbDownsampler::downsample(timestamps, values, threshold)
}

/// LTTB downsampler
pub struct LttbDownsampler;

impl LttbDownsampler {
    /// Execute LTTB downsampling
    ///
    /// # Arguments
    /// * `timestamps` - Array of timestamps
    /// * `values` - Array of values
    /// * `threshold` - Target number of points to return
    ///
    /// # Returns
    /// Tuple of (sampled_timestamps, sampled_values)
    pub fn downsample(
        timestamps: &[i64],
        values: &[f64],
        threshold: usize,
    ) -> (Vec<i64>, Vec<f64>) {
        let n = timestamps.len();

        // Boundary: fewer points than threshold, return all
        if n <= threshold {
            return (timestamps.to_vec(), values.to_vec());
        }

        let mut sampled_ts = Vec::with_capacity(threshold);
        let mut sampled_vals = Vec::with_capacity(threshold);

        // Bucket size for dividing data (excluding first and last points)
        let bucket_size = (n - 2) as f64 / (threshold - 2) as f64;

        // First point is always selected
        sampled_ts.push(timestamps[0]);
        sampled_vals.push(values[0]);

        // Track the original index of the last selected point
        let mut last_selected_original_idx: usize = 0;

        for i in 1..(threshold - 1) {
            // Current bucket boundaries
            let bucket_start = ((i - 1) as f64 * bucket_size).floor() as usize + 1;
            let bucket_end = (i as f64 * bucket_size).floor() as usize + 1;
            let bucket_end = bucket_end.min(n - 1);

            // Next bucket for calculating average point
            let next_bucket_start = bucket_end;
            let next_bucket_end = ((i + 1) as f64 * bucket_size).floor() as usize + 1;
            let next_bucket_end = next_bucket_end.min(n - 1);

            // Average point of next bucket (as triangle vertex)
            let avg_idx = next_bucket_start + (next_bucket_end - next_bucket_start) / 2;
            let avg_x = timestamps[avg_idx] as f64;
            let avg_y = values[avg_idx];

            // Find point in current bucket that forms largest triangle
            let mut max_area = -1.0;
            let mut max_idx = bucket_start;

            let last_x = timestamps[last_selected_original_idx] as f64;
            let last_y = values[last_selected_original_idx];

            for j in bucket_start..bucket_end {
                let area = Self::triangle_area(
                    last_x, last_y,
                    timestamps[j] as f64, values[j],
                    avg_x, avg_y,
                );
                if area > max_area {
                    max_area = area;
                    max_idx = j;
                }
            }

            sampled_ts.push(timestamps[max_idx]);
            sampled_vals.push(values[max_idx]);
            last_selected_original_idx = max_idx;
        }

        // Last point is always selected
        sampled_ts.push(timestamps[n - 1]);
        sampled_vals.push(values[n - 1]);

        (sampled_ts, sampled_vals)
    }

    /// Calculate triangle area using cross product formula
    ///
    /// Area = 0.5 * |cross(AB, AC)| = 0.5 * |(ax-cx)*(by-ay) - (ax-bx)*(cy-ay)|
    ///
    /// We omit the 0.5 factor since we only compare relative areas.
    #[inline]
    fn triangle_area(ax: f64, ay: f64, bx: f64, by: f64, cx: f64, cy: f64) -> f64 {
        ((ax - cx) * (by - ay) - (ax - bx) * (cy - ay)).abs()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_lttb_no_downsample_n_less_than_threshold() {
        let ts = vec![1_i64, 2, 3, 4, 5];
        let vals = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        let (sts, svals) = LttbDownsampler::downsample(&ts, &vals, 10);
        assert_eq!(sts, ts);
        assert_eq!(svals, vals);
    }

    #[test]
    fn test_lttb_no_downsample_n_equals_threshold() {
        let ts = vec![1_i64, 2, 3, 4, 5];
        let vals = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        let (sts, svals) = LttbDownsampler::downsample(&ts, &vals, 5);
        assert_eq!(sts, ts);
        assert_eq!(svals, vals);
    }

    #[test]
    fn test_lttb_downsample_returns_exact_threshold() {
        let ts: Vec<i64> = (0..100).map(|i| i as i64).collect();
        let vals: Vec<f64> = (0..100).map(|i| i as f64).collect();
        let (sts, svals) = LttbDownsampler::downsample(&ts, &vals, 10);
        assert_eq!(sts.len(), 10);
        assert_eq!(svals.len(), 10);
    }

    #[test]
    fn test_lttb_preserves_first_and_last() {
        let ts: Vec<i64> = (0..100).map(|i| i as i64 * 1000).collect();
        let vals: Vec<f64> = (0..100).map(|i| (i as f64).sin()).collect();
        let (sts, svals) = LttbDownsampler::downsample(&ts, &vals, 10);
        assert_eq!(sts.first(), Some(&ts[0]));
        assert_eq!(sts.last(), Some(&ts[99]));
        assert_eq!(svals.first(), Some(&vals[0]));
        assert_eq!(svals.last(), Some(&vals[99]));
    }

    #[test]
    fn test_lttb_minimum_threshold() {
        let ts = vec![1_i64, 2, 3, 4, 5];
        let vals = vec![1.0, 2.0, 3.0, 4.0, 5.0];
        let (sts, svals) = LttbDownsampler::downsample(&ts, &vals, 2);
        assert_eq!(sts.len(), 2);
        assert_eq!(svals.len(), 2);
        assert_eq!(sts[0], 1);
        assert_eq!(sts[1], 5);
    }

    #[test]
    fn test_lttb_empty_input() {
        let ts: Vec<i64> = vec![];
        let vals: Vec<f64> = vec![];
        let (sts, svals) = LttbDownsampler::downsample(&ts, &vals, 10);
        assert!(sts.is_empty());
        assert!(svals.is_empty());
    }

    #[test]
    fn test_lttb_single_point() {
        let ts = vec![42_i64];
        let vals = vec![2.71];
        let (sts, svals) = LttbDownsampler::downsample(&ts, &vals, 10);
        assert_eq!(sts.len(), 1);
        assert_eq!(svals.len(), 1);
        assert_eq!(sts[0], 42);
        assert_eq!(svals[0], 2.71);
    }

    #[test]
    fn test_lttb_standalone_function() {
        let ts: Vec<i64> = (0..100).map(|i| i as i64).collect();
        let vals: Vec<f64> = (0..100).map(|i| i as f64).collect();
        let (sts, svals) = lttb_downsample(&ts, &vals, 10);
        assert_eq!(sts.len(), 10);
        assert_eq!(svals.len(), 10);
        assert_eq!(sts.first(), Some(&ts[0]));
        assert_eq!(sts.last(), Some(&ts[99]));
    }
}
