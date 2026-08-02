//! What fraction of the true neighbours does the prefilter actually return?
//!
//! The tempting gate is `assert_eq!(brute, indexed)`. It is unachievable, and pretending
//! otherwise would mean either deleting the prefilter or weakening the assertion until it
//! says nothing. So the gate is a **recall floor**, measured against brute force on a
//! sample, and a floor that has to be re-measured rather than assumed when the sources or
//! their size thresholds change.
//!
//! Brute force is one anti-unification per declaration in the slice, so the sample is
//! small on purpose: 40 queries against 131k declarations is already 5.2 million LGGs.

use std::collections::HashSet;

use fh_atlas::skel::index::{IndexConfig, SkeletonIndex};

fn main() {
    let path = std::env::args().nth(1).unwrap();
    let floor: f64 = std::env::args()
        .nth(2)
        .and_then(|s| s.parse().ok())
        .unwrap_or(0.55);
    let text = std::fs::read_to_string(&path).unwrap();
    let cfg = IndexConfig::default();

    let t0 = std::time::Instant::now();
    let mut idx = SkeletonIndex::build(&text, &cfg).expect("build");
    println!(
        "index: {} declarations, {} signatures, {} + {} posting keys, {} degraded spines, {:.1}s",
        idx.len(),
        idx.signature_count(),
        idx.key_counts().0,
        idx.key_counts().1,
        idx.degraded_spines(),
        t0.elapsed().as_secs_f64()
    );

    // A deterministic spread through the corpus, so a regression is reproducible.
    let n = idx.len();
    let names: Vec<String> = (0..40)
        .map(|k| {
            idx.name_of(fh_atlas::skel::index::DeclId(((k * 3187 + 11) % n) as u32))
                .to_string()
        })
        .collect();

    let (mut found, mut total, mut queries) = (0usize, 0usize, 0usize);
    let mut worst: Option<(f64, String)> = None;
    let t1 = std::time::Instant::now();
    for name in &names {
        let Ok(brute) = idx.similar_brute(name, 5, &cfg) else {
            continue;
        };
        if brute.is_empty() {
            continue;
        }
        let truth: HashSet<&str> = brute.iter().map(|(n, _)| n.as_str()).collect();
        let Ok(fast) = idx.similar(name, 50, &cfg) else {
            continue;
        };
        let got: HashSet<&str> = fast.iter().map(|n| n.name.as_str()).collect();
        let hit = truth.iter().filter(|t| got.contains(*t)).count();
        found += hit;
        total += truth.len();
        queries += 1;
        let r = hit as f64 / truth.len() as f64;
        if worst.as_ref().is_none_or(|(w, _)| r < *w) {
            worst = Some((r, name.clone()));
        }
    }
    let recall = found as f64 / total.max(1) as f64;
    println!(
        "recall over {queries} queries: {found}/{total} = {:.1}%   ({:.1}s, brute included)",
        100.0 * recall,
        t1.elapsed().as_secs_f64()
    );
    if let Some((r, n)) = worst {
        println!("worst query: {n} at {:.0}%", 100.0 * r);
    }
    println!("floor: {:.0}%", 100.0 * floor);
    if recall < floor {
        eprintln!(
            "RECALL BELOW FLOOR. The prefilter's tuning does not hold on this slice; refit \
             the thresholds and re-pin the floor in a dedicated change rather than lowering it \
             here."
        );
        std::process::exit(1);
    }
}
