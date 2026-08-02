//! Index and query engine for the FH Atlas (atlas.md).
//!
//! Build order per atlas.md §5: dependency graph first, consuming JSONL rows
//! from the Lean-side extractor (atlas.md §6, Channel 2).

pub mod equiv;
pub mod graph;
pub mod json;
pub mod skel;
pub mod statement;
