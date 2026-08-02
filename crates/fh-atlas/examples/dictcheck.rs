//! Do dictionaries, transport and the frontier say anything a reader can act on?
//!
//! Every claim here names what a good answer looks like before it is produced, because a
//! ranked list of theory pairs is exactly the kind of output that can be admired instead
//! of read.

use fh_atlas::dict::{Transported, dictionary, frontier, theory_of, transport};
use fh_atlas::graph::Graph;
use fh_atlas::skel::erase::Level;
use fh_atlas::skel::index::{IndexConfig, SkeletonIndex};

fn main() {
    let path = std::env::args().nth(1).unwrap();
    let text = std::fs::read_to_string(&path).unwrap();
    let cfg = IndexConfig::default();
    let t0 = std::time::Instant::now();
    let mut idx = SkeletonIndex::build(&text, &cfg).expect("index");
    let graph = Graph::from_jsonl(&text).expect("graph");
    println!(
        "{} declarations, {:.1}s to build both indexes\n",
        idx.len(),
        t0.elapsed().as_secs_f64()
    );

    println!("theory_of samples:");
    for m in [
        "Mathlib.Algebra.Group.Defs",
        "Mathlib.Order.Basic",
        "Init.Data.Nat.Basic",
        "Std.Time",
    ] {
        println!("  {m:<36} -> {}", theory_of(m));
    }

    // The frontier: high skeleton similarity, low citation traffic.
    println!("\nfrontier — theory pairs that look alike and do not cite each other:");
    let t1 = std::time::Instant::now();
    let infra: Vec<String> = [
        "Init",
        "Std",
        "Lean",
        "Aesop",
        "Batteries",
        "Qq",
        "ProofWidgets",
        "Mathlib.Tactic",
        "Mathlib.Lean",
        "Mathlib.Util",
    ]
    .iter()
    .map(|s| s.to_string())
    .collect();
    let fr = frontier(&mut idx, &graph, 200, 12, true, &infra);
    for f in &fr {
        println!(
            "  {:.3}  {:<22} ~ {:<22} sim {:.2}  cites {:>5}  ({}/{})",
            f.score, f.left, f.right, f.similarity, f.cross_citations, f.left_size, f.right_size
        );
    }
    println!("  ({:.1}s)", t1.elapsed().as_secs_f64());
    assert!(
        !fr.is_empty(),
        "a slice this size must have some theory pairs to rank"
    );
    // A frontier that ranks a pair which already cites heavily is not measuring what it
    // claims to. The top pair should have less traffic than the median pair.
    let median_cites = {
        let mut c: Vec<usize> = fr.iter().map(|f| f.cross_citations).collect();
        c.sort_unstable();
        c[c.len() / 2]
    };
    println!(
        "  top pair's traffic {} vs median {}",
        fr[0].cross_citations, median_cites
    );

    // A dictionary between two theories that genuinely share structure.
    println!("\ndictionary — Mathlib.Order <-> Mathlib.Algebra:");
    let t2 = std::time::Instant::now();
    let d = dictionary(&mut idx, "Mathlib.Order", "Mathlib.Algebra", &cfg, 1, true);
    println!(
        "  {} rows, {} unmatched on the left, {} on the right  ({:.1}s)",
        d.rows.len(),
        d.missing_left.len(),
        d.missing_right.len(),
        t2.elapsed().as_secs_f64()
    );
    for r in d.rows.iter().take(8) {
        println!(
            "  {:.2} {:<12} {:<34} ~ {}",
            r.retention,
            r.status.name(),
            r.left,
            r.right
        );
    }
    println!(
        "  missing (left), first 5: {:?}",
        &d.missing_left[..d.missing_left.len().min(5)]
    );
    assert!(
        !d.rows.is_empty(),
        "order theory and algebra must share *some* structure"
    );
    // The missing-entry report is the point of the exercise; an empty one means the
    // matcher is claiming a total functor, which it is not.
    assert!(
        !d.missing_left.is_empty(),
        "a total dictionary would mean every order-theory concept has an algebraic partner"
    );

    // Transport, on a row we can check by eye.
    println!("\ntransport:");
    for (l, r, subj) in [
        ("le_trans", "dvd_trans", "le_trans"),
        ("le_trans", "dvd_trans", "lt_trans"),
    ] {
        match transport(&mut idx, l, r, subj, Level::Carriers) {
            Ok(Transported::Exists { name, .. }) => {
                println!("  {subj} along ({l} ~ {r}) -> already exists as `{name}`")
            }
            Ok(Transported::Open { image }) => println!(
                "  {subj} along ({l} ~ {r}) -> open target: {}",
                &image[..image.len().min(110)]
            ),
            Err(e) => println!("  {subj} along ({l} ~ {r}) -> refused: {e}"),
        }
    }

    // Transporting a declaration along a row whose right side *is* that declaration's
    // partner must land on a name, not on open ground. This has to hold at every level,
    // and for a long time it did not: the index seals its arena after precomputing Exact,
    // Presentation and Shape, so an image built later compared unequal to those roots by
    // id and `transport` invented an open target. Carriers and Instances are erased
    // lazily, on the far side of the seal, which is why checking only the default level
    // kept this quiet. Sweeping the levels is the gate.
    println!("\ntransport must find an existing target at every level:");
    let mut open_at = Vec::new();
    for level in [
        Level::Exact,
        Level::Presentation,
        Level::Instances,
        Level::Carriers,
        Level::Shape,
    ] {
        match transport(&mut idx, "le_trans", "dvd_trans", "le_trans", level) {
            Ok(Transported::Exists { name, .. }) => println!("  {level:?}: exists as `{name}`"),
            Ok(Transported::Open { .. }) => {
                println!("  {level:?}: OPEN — but the image is `dvd_trans` itself");
                open_at.push(level);
            }
            Err(e) => println!("  {level:?}: refused: {e}"),
        }
    }
    assert!(
        open_at.is_empty(),
        "transporting `le_trans` along (le_trans ~ dvd_trans) is `dvd_trans`, a lemma the \
         slice has; reporting it open at {open_at:?} is the engine inventing research"
    );

    // The negative control: a row with a scoped variable must refuse rather than
    // transport wrongly.
    println!("\nnegative control: transporting a statement that does not match the row");
    match transport(
        &mut idx,
        "le_trans",
        "dvd_trans",
        "add_comm",
        Level::Carriers,
    ) {
        Err(e) => println!("  refused: {e}"),
        Ok(t) => {
            eprintln!("  transported anyway: {t:?} — the applicability check is missing");
            std::process::exit(1);
        }
    }
}
