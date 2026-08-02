//! The ranking golden, as a test target rather than an artifact nobody runs.
//!
//! A golden file with no test that reads it is decoration. This one was written, pinned
//! and then never loaded by `cargo test`, because `crates/fh-atlas/tests/` contained no
//! `.rs` at all — so the regression gate for two changes that moved every score in the
//! corpus was, in effect, absent.
//!
//! It needs a real slice, which is 146 MB and not in the repo, so the test **skips** when
//! `FH_SLICE` is unset rather than failing. A skip is honest; a green tick that silently
//! measured nothing is not, and the skip says so on stdout.
//!
//!     FH_SLICE=/tmp/mathlib-algebra.jsonl cargo test -p fh-atlas --test golden

use std::collections::BTreeMap;

use fh_atlas::skel::index::{IndexConfig, SkeletonIndex};

const GOLDEN: &str = include_str!("golden/similar-algebra.txt");

/// Same list as `examples/goldencheck.rs`, and deliberately duplicated: if the two drift,
/// the diff says so rather than the golden silently covering a different question.
const QUERIES: [&str; 7] = [
    "le_trans",
    "dvd_trans",
    "Nat.mul_comm",
    "le_antisymm",
    "Nat.add_comm",
    "Nat.succ_le_succ",
    "And.comm",
];

fn render(idx: &mut SkeletonIndex, cfg: &IndexConfig) -> String {
    let mut out = String::new();
    for q in QUERIES {
        out.push_str(&format!("# {q}\n"));
        match idx.similar(q, 10, cfg) {
            Err(e) => out.push_str(&format!("  ERROR {e}\n")),
            Ok(ns) if ns.is_empty() => out.push_str("  (no neighbours)\n"),
            Ok(ns) => {
                let mut groups: BTreeMap<String, usize> = BTreeMap::new();
                for n in &ns {
                    *groups.entry(format!("{:.4}", n.score)).or_default() += 1;
                }
                for n in &ns {
                    let key = format!("{:.4}", n.score);
                    out.push_str(&format!(
                        "  {key}  tie{:<2}  ret {:.3}  common {:>3}  vars {:>2}  [{}]  {}\n",
                        groups[&key],
                        n.retention,
                        n.common,
                        n.vars,
                        n.sources.describe(),
                        n.name,
                    ));
                }
            }
        }
    }
    out
}

#[test]
fn the_ranking_matches_the_pinned_golden() {
    let Ok(path) = std::env::var("FH_SLICE") else {
        println!("SKIPPED: set FH_SLICE to a B1 JSONL slice to run the ranking golden");
        return;
    };
    let src = std::fs::read_to_string(&path).expect("read slice");
    let cfg = IndexConfig::default();
    let mut idx = SkeletonIndex::build(&src, &cfg).expect("build index");
    let now = render(&mut idx, &cfg);
    if now != GOLDEN {
        // Print the drift rather than just asserting, so a reviewer decides whether the
        // change is the intended one instead of re-recording the file to make it quiet.
        let (a, b): (Vec<&str>, Vec<&str>) = (GOLDEN.lines().collect(), now.lines().collect());
        for i in 0..a.len().max(b.len()) {
            match (a.get(i), b.get(i)) {
                (Some(x), Some(y)) if x == y => {}
                (x, y) => {
                    if let Some(x) = x {
                        println!("- {x}");
                    }
                    if let Some(y) = y {
                        println!("+ {y}");
                    }
                }
            }
        }
        panic!("ranking drifted from the golden; review the diff above before re-pinning");
    }
}

/// The property the golden cannot express, and the one the tie-break bug actually broke:
/// within a tie class, order must be decided by *content* before it is decided by the
/// alphabet. `dvd_trans` fell out of `le_trans`'s top five because lowercase sorts after
/// every capitalised name.
#[test]
fn ties_are_broken_by_content_before_the_alphabet() {
    let Ok(path) = std::env::var("FH_SLICE") else {
        println!("SKIPPED: set FH_SLICE to a B1 JSONL slice");
        return;
    };
    let src = std::fs::read_to_string(&path).expect("read slice");
    let cfg = IndexConfig::default();
    let mut idx = SkeletonIndex::build(&src, &cfg).expect("build index");
    let ns = idx.similar("le_trans", 20, &cfg).expect("similar");
    for w in ns.windows(2) {
        let (a, b) = (&w[0], &w[1]);
        if a.score != b.score {
            continue;
        }
        assert!(
            a.common > b.common || (a.common == b.common && a.vars <= b.vars),
            "within a tie class, `{}` (common {}, vars {}) precedes `{}` (common {}, vars {}) \
             on nothing but its name",
            a.name,
            a.common,
            a.vars,
            b.name,
            b.common,
            b.vars
        );
    }
}
