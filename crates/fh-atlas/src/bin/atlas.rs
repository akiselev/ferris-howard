//! `atlas` — queries over an extraction (atlas.md §2, B2).
//!
//! ```text
//! lake exe atlas_extract Mathlib.Logic.Basic > slice.jsonl
//! atlas why  slice.jsonl Nat.Prime.dvd_mul Nat.Prime
//! atlas foundations slice.jsonl Nat.Prime.dvd_mul
//! atlas impact      slice.jsonl Nat.Prime
//! atlas walls       slice.jsonl
//! ```
//!
//! Every query takes a `--lens` of `statement`, `proof` or `both` (default). The lens is
//! not a detail: what a *claim* rests on and what an *argument* rests on are different
//! questions, and B1 emits them as separate edge sets precisely so a query can ask one
//! without the other.

use std::process::ExitCode;

use fh_atlas::graph::{Graph, Lens};

const USAGE: &str = "\
usage: atlas <query> <slice.jsonl> [args] [--lens statement|proof|both]

queries:
  why <from> <to>     a shortest dependency chain from <from> down to <to>
  foundations <name>  everything <name> transitively rests on
  impact <name>       everything that transitively rests on <name>
  walls               declarations ranked by how many others cite them
  honesty [axiom...]  declarations resting on `sorryAx` or on an axiom outside the
                      whitelist; exits non-zero if any are found
  stats               size of the slice, and how much of it encodes

The lens selects which edges are walked: `statement` is what claims rest on, `proof` is
what arguments rest on, `both` is the citation graph. Default: both.
";

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    match run(&args) {
        // `honesty` reports findings on stdout and still exits non-zero — the findings are
        // the answer, not an error, but CI has to be able to fail on them.
        Ok(Report { text, clean }) => {
            print!("{text}");
            if clean {
                ExitCode::SUCCESS
            } else {
                ExitCode::FAILURE
            }
        }
        Err(msg) => {
            eprintln!("atlas: {msg}");
            ExitCode::FAILURE
        }
    }
}

/// A query's output, and whether it should exit zero.
struct Report {
    text: String,
    clean: bool,
}

impl From<String> for Report {
    fn from(text: String) -> Report {
        Report { text, clean: true }
    }
}

fn run(args: &[String]) -> Result<Report, String> {
    let (lens, rest) = take_lens(args)?;
    let (query, rest) = rest.split_first().ok_or_else(|| USAGE.to_string())?;
    let (path, rest) = rest.split_first().ok_or_else(|| USAGE.to_string())?;
    let input = std::fs::read_to_string(path).map_err(|e| format!("{path}: {e}"))?;
    let g = Graph::from_jsonl(&input).map_err(|e| e.to_string())?;

    match query.as_str() {
        "why" => {
            let [from, to] = rest else {
                return Err("why takes two declaration names".into());
            };
            known(&g, from)?;
            match g.why(from, to, lens) {
                // The chain is printed one name per line rather than joined, because the
                // thing an agent does next is read it top to bottom.
                Some(path) => Ok((path.join("\n") + "\n").into()),
                None => Err(format!(
                    "no dependency chain from `{from}` to `{to}` in this slice"
                )),
            }
        }
        "foundations" => {
            let [name] = rest else {
                return Err("foundations takes one declaration name".into());
            };
            known(&g, name)?;
            Ok(lines(g.foundations(name, lens)).into())
        }
        "impact" => {
            let [name] = rest else {
                return Err("impact takes one declaration name".into());
            };
            // Not `known`: asking what rests on something outside the slice is a fair
            // question, and the answer is the part of the slice that cites it.
            Ok(lines(g.impact(name, lens)).into())
        }
        "walls" => {
            let mut out = String::new();
            // Direct citations, not transitive impact: ranking a whole slice
            // transitively is one BFS per node, and a Mathlib slice is 75,000 of them.
            // Ask `impact <name>` for the transitive answer about one declaration.
            for (name, n) in g.ranked_by_citations(lens).into_iter().take(20) {
                if n == 0 {
                    break;
                }
                out.push_str(&format!("{n:>6}  {name}\n"));
            }
            Ok(out.into())
        }
        "honesty" => {
            // C5's transitive-sorry scan, which the dependency graph answers directly:
            // everything resting on `sorryAx` is its impact under the proof lens. The
            // scan is *transitive* on purpose — a complete-looking theorem one step above
            // a hole is not complete, and that is the case anti-cheat exists to catch.
            let mut findings: Vec<(String, String)> = g
                .impact("sorryAx", Lens::Proof)
                .into_iter()
                .map(|n| (n, "sorryAx".to_string()))
                .collect();
            // The whitelist is the axioms an argument may rest on. Default: Lean's own
            // three, which everything classical uses. Anything else is named.
            let allowed: Vec<String> = if rest.is_empty() {
                ["propext", "Classical.choice", "Quot.sound"]
                    .iter()
                    .map(|s| s.to_string())
                    .collect()
            } else {
                rest.to_vec()
            };
            for name in g.names() {
                if g.get(name).is_some_and(|d| d.kind == "axiom")
                    && !allowed.contains(name)
                    && name != "sorryAx"
                {
                    for user in g.impact(name, Lens::Proof) {
                        findings.push((user, name.clone()));
                    }
                }
            }
            findings.sort();
            findings.dedup();
            if findings.is_empty() {
                return Ok(format!("honesty: clean — {} declarations\n", g.len()).into());
            }
            let mut out = String::new();
            for (who, why) in &findings {
                out.push_str(&format!("{who}  rests on  {why}\n"));
            }
            out.push_str(&format!("honesty: {} finding(s)\n", findings.len()));
            Ok(Report {
                text: out,
                clean: false,
            })
        }
        "stats" => {
            let total = g.len();
            let encoded = g
                .names()
                .filter(|n| g.get(n).is_some_and(|d| d.stmt.is_some()))
                .count();
            Ok(format!(
                "declarations: {total}\nencoded statements: {encoded}\nunencodable: {}\n",
                total - encoded
            )
            .into())
        }
        other => Err(format!("unknown query `{other}`\n\n{USAGE}")),
    }
}

fn known(g: &Graph, name: &str) -> Result<(), String> {
    if g.get(name).is_some() {
        Ok(())
    } else {
        Err(format!("`{name}` is not in this slice"))
    }
}

fn lines(names: impl IntoIterator<Item = String>) -> String {
    let mut out = String::new();
    for n in names {
        out.push_str(&n);
        out.push('\n');
    }
    out
}

fn take_lens(args: &[String]) -> Result<(Lens, Vec<String>), String> {
    let mut lens = Lens::Both;
    let mut rest = Vec::new();
    let mut it = args.iter();
    while let Some(a) = it.next() {
        if a == "--lens" {
            let v = it.next().ok_or("--lens takes a value")?;
            lens = match v.as_str() {
                "statement" => Lens::Statement,
                "proof" => Lens::Proof,
                "both" => Lens::Both,
                other => return Err(format!("unknown lens `{other}`")),
            };
        } else {
            rest.push(a.clone());
        }
    }
    Ok((lens, rest))
}
