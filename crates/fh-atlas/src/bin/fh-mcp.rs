//! `fh mcp` v0 — the agent-facing surface (C3, agent-interface.md §1).
//!
//! JSON-RPC 2.0 over stdio, one message per line.
//!
//! # What this server does *not* do, on purpose
//!
//! agent-interface.md §1, as amended 2026-08-01:
//!
//! > the generic layer — goals, diagnostics, hover, and the search fan-out including
//! > Loogle/LeanSearch — is delegated to the community `lean-lsp-mcp` server, which
//! > already ships all of it against any Lake project; `fh mcp` itself implements only the
//! > FH-specific tools. Composition over reimplementation.
//!
//! So there is no `search` here, and no `goals` in the LSP sense. `elaborate` returns
//! `fh check`'s JSON, which carries goals at **FH-source** spans — the one thing a generic
//! server cannot produce, because it does not know the macro expansion happened.
//!
//! # Tools
//!
//! * `elaborate` — run `fh check` over a file and return its report verbatim.
//! * `atlas_why`, `atlas_foundations`, `atlas_impact`, `atlas_walls` — B2's queries.
//! * `statement_verify` — the I3 anti-cheat check: does an encoding still match a frozen
//!   digest, or has the statement drifted?
//! * `status` — is the toolchain reachable and the build warm?
//!
//! `try` and `minimize` are named in §1 and are **not here**: both need proof-state
//! handles, which means the REPL wrapper (C2). Missing rather than stubbed, because a tool
//! that answers badly is worse than one that is absent.

use std::io::{BufRead, Write};
use std::path::Path;
use std::process::Command;

use fh_atlas::graph::{Graph, Lens};
use fh_atlas::json::{self, Value};
use fh_atlas::statement;

const PROTOCOL_VERSION: &str = "2024-11-05";

fn main() {
    let stdin = std::io::stdin();
    let mut stdout = std::io::stdout();
    for line in stdin.lock().lines() {
        let Ok(line) = line else { break };
        let line = line.trim();
        if line.is_empty() {
            continue;
        }
        if let Some(response) = handle_line(line) {
            let _ = writeln!(stdout, "{response}");
            let _ = stdout.flush();
        }
    }
}

/// One request in, at most one response out.
///
/// A JSON-RPC *notification* has no `id` and takes no reply — `notifications/initialized`
/// is the one every client sends, and answering it is a protocol error rather than a
/// harmless extra.
fn handle_line(line: &str) -> Option<String> {
    let req = match json::parse(line) {
        Ok(v) => v,
        Err(e) => {
            return Some(error_response(
                Value::Null,
                -32700,
                &format!("parse error: {e}"),
            ));
        }
    };
    let id = req.get("id").cloned();
    let method = req.get("method").and_then(|m| m.as_str()).unwrap_or("");
    let params = req.get("params").cloned().unwrap_or(Value::Null);

    // No `id` means a notification, and JSON-RPC says a notification takes no reply.
    let id = id?;

    match method {
        "initialize" => Some(ok_response(id, initialize_result())),
        "tools/list" => Some(ok_response(id, Value::obj([("tools", tool_list())]))),
        "tools/call" => match call_tool(&params) {
            Ok(text) => Some(ok_response(
                id,
                Value::obj([
                    (
                        "content",
                        Value::List(vec![Value::obj([
                            ("type", Value::str("text")),
                            ("text", Value::str(text)),
                        ])]),
                    ),
                    ("isError", Value::Bool(false)),
                ]),
            )),
            // A tool that fails reports through `isError` rather than a JSON-RPC error:
            // the failure is the agent's answer, not a transport fault, and it should
            // reach the model as content it can read.
            Err(msg) => Some(ok_response(
                id,
                Value::obj([
                    (
                        "content",
                        Value::List(vec![Value::obj([
                            ("type", Value::str("text")),
                            ("text", Value::str(msg)),
                        ])]),
                    ),
                    ("isError", Value::Bool(true)),
                ]),
            )),
        },
        "ping" => Some(ok_response(id, Value::obj([]))),
        other => Some(error_response(
            id,
            -32601,
            &format!("unknown method `{other}`"),
        )),
    }
}

fn initialize_result() -> Value {
    Value::obj([
        ("protocolVersion", Value::str(PROTOCOL_VERSION)),
        ("capabilities", Value::obj([("tools", Value::obj([]))])),
        (
            "serverInfo",
            Value::obj([
                ("name", Value::str("fh-mcp")),
                ("version", Value::str(env!("CARGO_PKG_VERSION"))),
            ]),
        ),
    ])
}

fn string_schema(fields: &[(&str, &str)], required: &[&str]) -> Value {
    let props: Vec<(String, Value)> = fields
        .iter()
        .map(|(name, desc)| {
            (
                name.to_string(),
                Value::obj([
                    ("type", Value::str("string")),
                    ("description", Value::str(*desc)),
                ]),
            )
        })
        .collect();
    Value::obj([
        ("type", Value::str("object")),
        ("properties", Value::Obj(props.into_iter().collect())),
        (
            "required",
            Value::List(required.iter().map(|r| Value::str(*r)).collect()),
        ),
    ])
}

fn tool(name: &str, description: &str, schema: Value) -> Value {
    Value::obj([
        ("name", Value::str(name)),
        ("description", Value::str(description)),
        ("inputSchema", schema),
    ])
}

const LENS_DOC: &str = "which edges to walk: `statement` (what the claim rests on), \
                        `proof` (what the argument rests on), or `both` (default)";

fn tool_list() -> Value {
    Value::List(vec![
        tool(
            "elaborate",
            "Elaborate an FH file and return `fh check`'s JSON: status, diagnostics with \
             FH-source spans, the goal and local context at every hole, and each \
             declaration's binders and axioms. This is the edit -> check -> read goals \
             loop agent-interface.md calls 90% of an agent's work.",
            string_schema(
                &[(
                    "file",
                    "path to the .lean file, relative to the lean/ directory",
                )],
                &["file"],
            ),
        ),
        tool(
            "atlas_why",
            "A shortest citation chain from one declaration down to another. The \
             'decompile the relationship' primitive: the first thing to run when asked \
             whether X is relevant to Y.",
            string_schema(
                &[
                    ("slice", "path to a JSONL extraction from `atlas_extract`"),
                    ("from", "the declaration to start from"),
                    ("to", "the declaration to reach"),
                    ("lens", LENS_DOC),
                ],
                &["slice", "from", "to"],
            ),
        ),
        tool(
            "atlas_foundations",
            "Everything a declaration transitively rests on.",
            string_schema(
                &[
                    ("slice", "path to a JSONL extraction"),
                    ("name", "the declaration"),
                    ("lens", LENS_DOC),
                ],
                &["slice", "name"],
            ),
        ),
        tool(
            "atlas_impact",
            "Everything that transitively rests on a declaration — what breaks if it is \
             wrong.",
            string_schema(
                &[
                    ("slice", "path to a JSONL extraction"),
                    ("name", "the declaration"),
                    ("lens", LENS_DOC),
                ],
                &["slice", "name"],
            ),
        ),
        tool(
            "atlas_walls",
            "The declarations most cited in a slice: the load-bearing walls.",
            string_schema(
                &[("slice", "path to a JSONL extraction"), ("lens", LENS_DOC)],
                &["slice"],
            ),
        ),
        tool(
            "statement_verify",
            "The anti-cheat check: does a statement encoding still match a frozen digest? \
             Answers `match`, `differs`, or `stale-freeze` — a version skew is a distinct \
             verdict from a changed statement, and conflating them would let a toolchain \
             bump read as tampering.",
            string_schema(
                &[
                    (
                        "encoding",
                        "the canonical statement encoding, from `#fh_statement`",
                    ),
                    ("frozen", "the digest to check against"),
                ],
                &["encoding", "frozen"],
            ),
        ),
        tool(
            "status",
            "Toolchain and build health: which Lean is on PATH, and whether the Lake \
             build is warm.",
            string_schema(&[], &[]),
        ),
    ])
}

fn call_tool(params: &Value) -> Result<String, String> {
    let name = params
        .get("name")
        .and_then(|v| v.as_str())
        .ok_or("tools/call needs a `name`")?;
    let args = params
        .get("arguments")
        .cloned()
        .unwrap_or(Value::Obj(Default::default()));
    let arg = |k: &str| -> Result<String, String> {
        args.get(k)
            .and_then(|v| v.as_str())
            .map(str::to_string)
            .ok_or_else(|| format!("`{name}` needs a `{k}`"))
    };
    let lens = match args.get("lens").and_then(|v| v.as_str()).unwrap_or("both") {
        "statement" => Lens::Statement,
        "proof" => Lens::Proof,
        "both" => Lens::Both,
        other => return Err(format!("unknown lens `{other}`")),
    };
    let load = |path: &str| -> Result<Graph, String> {
        let text = std::fs::read_to_string(path).map_err(|e| format!("{path}: {e}"))?;
        Graph::from_jsonl(&text).map_err(|e| e.to_string())
    };

    match name {
        "elaborate" => elaborate(&arg("file")?),
        "atlas_why" => {
            let g = load(&arg("slice")?)?;
            let (from, to) = (arg("from")?, arg("to")?);
            g.why(&from, &to, lens)
                .map(|p| p.join("\n"))
                .ok_or_else(|| format!("no dependency chain from `{from}` to `{to}` in this slice"))
        }
        "atlas_foundations" => {
            let g = load(&arg("slice")?)?;
            Ok(g.foundations(&arg("name")?, lens)
                .into_iter()
                .collect::<Vec<_>>()
                .join("\n"))
        }
        "atlas_impact" => {
            let g = load(&arg("slice")?)?;
            Ok(g.impact(&arg("name")?, lens)
                .into_iter()
                .collect::<Vec<_>>()
                .join("\n"))
        }
        "atlas_walls" => {
            let g = load(&arg("slice")?)?;
            Ok(g.ranked_by_citations(lens)
                .into_iter()
                .take(20)
                .filter(|(_, n)| *n > 0)
                .map(|(name, n)| format!("{n:>6}  {name}"))
                .collect::<Vec<_>>()
                .join("\n"))
        }
        "statement_verify" => {
            let verdict = statement::verify(&arg("encoding")?, &arg("frozen")?)
                .map_err(|e| format!("{e:?}"))?;
            Ok(format!("{verdict:?}"))
        }
        "status" => Ok(status()),
        other => Err(format!("unknown tool `{other}`")),
    }
}

/// Run `fh check` and hand back its report unchanged.
///
/// Shelling out rather than linking: `fh check` is a Lean program with a Lean environment
/// behind it, and its JSON is already the contract this tool is specified to serve. A
/// second implementation here would be a second thing to keep in step.
fn elaborate(file: &str) -> Result<String, String> {
    let lean_dir = lean_dir();
    if !lean_dir.join(file).exists() {
        return Err(format!(
            "no such file: {file} (relative to {})",
            lean_dir.display()
        ));
    }
    let out = Command::new("lake")
        .args(["exe", "fh_check", file])
        .current_dir(&lean_dir)
        .output()
        .map_err(|e| format!("could not run `lake exe fh_check`: {e}"))?;
    let stdout = String::from_utf8_lossy(&out.stdout);
    // `fh check` exits non-zero when the file has errors, and that report is exactly what
    // an agent is asking for — a non-zero exit is a result, not a failure to answer.
    match stdout.find('{') {
        Some(i) => Ok(stdout[i..].to_string()),
        None => Err(format!(
            "fh check produced no report:\n{}",
            String::from_utf8_lossy(&out.stderr)
        )),
    }
}

fn lean_dir() -> std::path::PathBuf {
    if let Ok(d) = std::env::var("FH_LEAN_DIR") {
        return d.into();
    }
    let cwd = std::env::current_dir().unwrap_or_else(|_| ".".into());
    if cwd.join("lakefile.toml").exists() {
        cwd
    } else {
        cwd.join("lean")
    }
}

fn status() -> String {
    let lean_dir = lean_dir();
    let version = Command::new("lean")
        .arg("--version")
        .output()
        .ok()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_else(|| "lean not on PATH".into());
    let warm = Path::new(&lean_dir).join(".lake/build/lib/lean").exists();
    Value::obj([
        ("lean", Value::str(version)),
        ("leanDir", Value::str(lean_dir.display().to_string())),
        ("buildWarm", Value::Bool(warm)),
    ])
    .to_json()
}

fn ok_response(id: Value, result: Value) -> String {
    Value::obj([
        ("jsonrpc", Value::str("2.0")),
        ("id", id),
        ("result", result),
    ])
    .to_json()
}

fn error_response(id: Value, code: i64, message: &str) -> String {
    Value::obj([
        ("jsonrpc", Value::str("2.0")),
        ("id", id),
        (
            "error",
            Value::obj([
                ("code", Value::Num(code as f64)),
                ("message", Value::str(message)),
            ]),
        ),
    ])
    .to_json()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn call(line: &str) -> Value {
        json::parse(&handle_line(line).expect("expected a response")).unwrap()
    }

    #[test]
    fn initialize_announces_tools() {
        let r = call(r#"{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}"#);
        assert_eq!(r.get("id"), Some(&Value::Num(1.0)));
        let caps = r.get("result").unwrap().get("capabilities").unwrap();
        assert!(caps.get("tools").is_some());
    }

    #[test]
    fn a_notification_gets_no_reply() {
        // JSON-RPC: no `id` means no response. Every client sends
        // `notifications/initialized`, and answering it is a protocol error.
        assert!(handle_line(r#"{"jsonrpc":"2.0","method":"notifications/initialized"}"#).is_none());
    }

    #[test]
    fn tools_list_names_the_fh_specific_ones_only() {
        let r = call(r#"{"jsonrpc":"2.0","id":2,"method":"tools/list"}"#);
        let tools = r
            .get("result")
            .unwrap()
            .get("tools")
            .unwrap()
            .as_list()
            .unwrap();
        let names: Vec<&str> = tools
            .iter()
            .filter_map(|t| t.get("name"))
            .filter_map(|n| n.as_str())
            .collect();
        assert!(names.contains(&"elaborate"));
        assert!(names.contains(&"atlas_why"));
        assert!(names.contains(&"statement_verify"));
        // Delegated to `lean-lsp-mcp` per agent-interface §1's amendment: composition
        // over reimplementation. A `search` here would be the second-best one.
        assert!(!names.contains(&"search"));
        // Named in §1 but honestly absent until the REPL wrapper (C2) exists.
        assert!(!names.contains(&"try"));
        assert!(!names.contains(&"minimize"));
        // Every tool has to declare a schema, or a client cannot call it.
        for t in tools {
            assert!(t.get("inputSchema").is_some(), "{t:?} has no inputSchema");
            assert!(t.get("description").is_some(), "{t:?} has no description");
        }
    }

    #[test]
    fn a_tool_failure_is_content_not_a_transport_error() {
        // The failure is the agent's answer. Reporting it as a JSON-RPC error would hide
        // it from the model, which is the one reader who needs it.
        let r = call(
            r#"{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"atlas_why","arguments":{"slice":"/nonexistent.jsonl","from":"A","to":"B"}}}"#,
        );
        assert!(r.get("error").is_none());
        let res = r.get("result").unwrap();
        assert_eq!(res.get("isError"), Some(&Value::Bool(true)));
        let text = res.get("content").unwrap().as_list().unwrap()[0]
            .get("text")
            .unwrap();
        assert!(text.as_str().unwrap().contains("nonexistent"), "{text:?}");
    }

    #[test]
    fn atlas_queries_answer_over_a_slice() {
        let dir = std::env::temp_dir().join("fh-mcp-test");
        std::fs::create_dir_all(&dir).unwrap();
        let slice = dir.join("slice.jsonl");
        std::fs::write(
            &slice,
            "{\"name\":\"A\",\"kind\":\"theorem\",\"module\":\"M\",\"uses_statement\":[],\"uses_proof\":[\"B\"]}\n\
             {\"name\":\"B\",\"kind\":\"theorem\",\"module\":\"M\",\"uses_statement\":[],\"uses_proof\":[\"C\"]}\n\
             {\"name\":\"C\",\"kind\":\"def\",\"module\":\"M\",\"uses_statement\":[],\"uses_proof\":[]}\n",
        )
        .unwrap();
        let s = slice.display().to_string();
        let req = format!(
            r#"{{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{{"name":"atlas_why","arguments":{{"slice":"{s}","from":"A","to":"C","lens":"proof"}}}}}}"#
        );
        let r = call(&req);
        let res = r.get("result").unwrap();
        assert_eq!(res.get("isError"), Some(&Value::Bool(false)));
        let text = res.get("content").unwrap().as_list().unwrap()[0]
            .get("text")
            .unwrap();
        assert_eq!(text.as_str().unwrap(), "A\nB\nC");
    }

    #[test]
    fn statement_verify_distinguishes_drift_from_version_skew() {
        let enc = "fh-stmt-v1;s(u0)";
        let digest = statement::digest(enc).unwrap();
        let call_with = |encoding: &str| {
            let req = format!(
                r#"{{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{{"name":"statement_verify","arguments":{{"encoding":"{encoding}","frozen":"{digest}"}}}}}}"#
            );
            let r = call(&req);
            r.get("result")
                .unwrap()
                .get("content")
                .unwrap()
                .as_list()
                .unwrap()[0]
                .get("text")
                .unwrap()
                .as_str()
                .unwrap()
                .to_string()
        };
        assert_eq!(call_with(enc), "Match");
        assert_eq!(call_with("fh-stmt-v1;s(u1)"), "Differs");
    }

    #[test]
    fn an_unknown_method_is_a_jsonrpc_error() {
        let r = call(r#"{"jsonrpc":"2.0","id":6,"method":"nope"}"#);
        assert_eq!(
            r.get("error").unwrap().get("code"),
            Some(&Value::Num(-32601.0))
        );
    }

    #[test]
    fn malformed_input_does_not_kill_the_server() {
        let r = call("not json");
        assert_eq!(
            r.get("error").unwrap().get("code"),
            Some(&Value::Num(-32700.0))
        );
    }
}
