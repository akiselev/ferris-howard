-- E3: #guard_msgs semantics: exact vs substring
/-- error: Unknown identifier `zzz` -/
#guard_msgs in
example : Nat := zzz

-- substring only (should FAIL if exact-match)
/-- error: zzz -/
#guard_msgs in
example : Nat := zzz
