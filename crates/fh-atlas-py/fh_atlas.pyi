"""Type stubs for the Atlas Python binding.

The `Corpus` namespace of `research/python-api.md` §2. Nothing else is bound yet — see
`crates/fh-atlas-py/README.md` for what is missing and why.
"""

from __future__ import annotations

import os
from typing import Literal

Lens = Literal["statement", "proof", "both"]
"""Which dependency edges a query walks.

`statement` is what a claim rests on, `proof` is what an argument rests on, `both` is the
citation graph as a reader would draw it. The distinction is not a detail: "can I weaken
this hypothesis" is the first question, "what breaks if this proof is wrong" the second.
"""

Level = Literal["exact", "presentation", "instances", "carriers", "shape"]
"""How much to squint. The levels are a chain: coarser buckets are unions of finer ones."""

class AtlasError(Exception):
    """Base class for every error this module raises."""

class SliceError(AtlasError):
    """A slice could not be read as B1 JSONL. The message names the offending line."""

class UnknownDeclaration(AtlasError):
    """No declaration by that name in this slice."""

class NoStatement(AtlasError):
    """The declaration is in the slice but carries no usable I3 statement encoding."""

class Decl:
    """One declaration, as B1's extractor emitted it."""

    @property
    def name(self) -> str: ...
    @property
    def kind(self) -> str: ...
    @property
    def module(self) -> str: ...
    @property
    def stmt(self) -> str | None:
        """The I3 canonical statement encoding, `None` when it could not be encoded."""

    @property
    def stmt_error(self) -> str | None:
        """Why `stmt` is absent. Present exactly when `stmt` is absent."""

    def __repr__(self) -> str: ...

class Generalization:
    """The least general generalization of two statements, with the numbers that rank it."""

    @property
    def skeleton(self) -> str:
        """Rendered in the I3 grammar: `_` is a hole, `?k` an anti-unification variable."""

    @property
    def common(self) -> int:
        """Non-hole, non-variable nodes — how much structure the two actually share."""

    @property
    def vars(self) -> int: ...
    @property
    def scoped_vars(self) -> int:
        """Variables standing for something with loose de Bruijn indices.

        Such a row reads fine and is **not** transportable. Never zero-by-omission: if this
        is positive, the generalization is a local coincidence rather than a dictionary row.
        """

    @property
    def retention(self) -> float:
        """`common / max(|x|,|y|)`, in `[0,1]`; exactly 1 when the statements are equal."""

    def __repr__(self) -> str: ...

class Corpus:
    """A parsed slice: one load, many queries.

    Loading parses the whole JSONL once (~6 s for 131k declarations); every query below
    then runs against the graph already in memory.
    """

    @staticmethod
    def load(path: str | os.PathLike[str]) -> Corpus:
        """Read and parse a B1 JSONL slice.

        Raises:
            FileNotFoundError: no file at `path`.
            SliceError: a row is not valid JSON or lacks a `name`.
        """

    def __len__(self) -> int:
        """How many declarations the slice holds."""

    def __repr__(self) -> str: ...
    def names(self) -> list[str]:
        """Every declaration name in the slice, sorted."""

    def get(self, name: str) -> Decl | None:
        """One declaration, or `None` if the slice does not have it."""

    def why(self, source: str, target: str, lens: Lens = "both") -> list[str] | None:
        """A shortest dependency chain from `source` down to `target`.

        `None` when no chain exists under this lens — which is an answer, not an error.
        `target` need not be in the slice: an edge out of the slice is a real fact about it.

        Raises:
            UnknownDeclaration: `source` is not in the slice.
            ValueError: `lens` is not one of the three names.
        """

    def foundations(self, name: str, lens: Lens = "both") -> list[str]:
        """Everything `name` transitively rests on, sorted. Excludes `name` itself.

        Raises:
            UnknownDeclaration: `name` is not in the slice.
            ValueError: `lens` is not one of the three names.
        """

    def impact(self, name: str, lens: Lens = "both") -> list[str]:
        """Everything that transitively rests on `name`, sorted.

        Unlike the other queries this does not require `name` to be in the slice: asking
        what rests on something outside it is a fair question, and the answer is the part
        of the slice that cites it.

        Raises:
            ValueError: `lens` is not one of the three names.
        """

    def walls(self, lens: Lens = "both", top: int = 20) -> list[tuple[str, int]]:
        """Declarations ranked by how many others cite them *directly*, most-cited first.

        Direct, not transitive: ranking a whole slice transitively is one BFS per node.
        Declarations nothing cites are omitted rather than padding the list with zeros, so
        the result may be shorter than `top`.
        """

    def honesty(self, whitelist: list[str] | None = None) -> list[tuple[str, str]]:
        """Declarations resting on `sorryAx` or on an axiom outside `whitelist`.

        Returns `(who, why)` pairs, sorted and deduplicated; an empty list means clean. The
        scan is transitive: a complete-looking theorem one step above a hole is not
        complete.

        `whitelist=None` means Lean's own three axioms (`propext`, `Classical.choice`,
        `Quot.sound`). An explicit list is used exactly as given, so `[]` allows nothing.
        """

    def skeleton(self, name: str, level: Level = "carriers") -> str:
        """The declaration's statement erased to `level`, rendered in the I3 grammar.

        Two statements are analogous at a level exactly when this string is equal for both.

        Raises:
            UnknownDeclaration: `name` is not in the slice.
            NoStatement: the row carries no statement, or one the parser rejected.
            ValueError: `level` is not one of the five names.
        """

    def generalize(self, left: str, right: str) -> Generalization:
        """Anti-unify two statements: the most specific term that matches both.

        Over the statements as encoded, not as erased — the concrete part is what the two
        theorems genuinely share and each variable is a place where they differ.

        Raises:
            UnknownDeclaration: either name is not in the slice.
            NoStatement: either row carries no usable statement.
        """
