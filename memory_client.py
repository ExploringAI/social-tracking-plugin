"""
Thin async wrapper that calls Mazemaker's neural_* tool functions.

This module abstracts whether we're calling tools via the Hermes tool
registry or via direct Python imports from the installed mazemaker package.
"""
from __future__ import annotations
import logging
from typing import Any, Optional

logger = logging.getLogger(__name__)


class MemoryClient:
    """
    Wraps Mazemaker neural_* tools.

    Parameters
    ----------
    tool_registry : dict, optional
        Mapping of tool_name -> callable, supplied by the Hermes plugin
        context.  Falls back to direct mazemaker imports if None.
    """

    def __init__(self, tool_registry: Optional[dict] = None):
        self._reg = tool_registry or {}
        self._direct: Optional[Any] = None  # mazemaker module handle

    # ------------------------------------------------------------------
    # Internal dispatch
    # ------------------------------------------------------------------
    def _call(self, tool_name: str, **kwargs) -> Any:
        if tool_name in self._reg:
            return self._reg[tool_name](**kwargs)
        # Fallback: try importing mazemaker tools directly
        if self._direct is None:
            try:
                import mazemaker.tools as _mt  # noqa: PLC0415
                self._direct = _mt
            except ImportError as exc:
                raise RuntimeError(
                    f"Tool '{tool_name}' not in registry and mazemaker.tools"
                    f" not importable: {exc}"
                ) from exc
        fn = getattr(self._direct, tool_name, None)
        if fn is None:
            raise AttributeError(
                f"mazemaker.tools has no attribute '{tool_name}'"
            )
        return fn(**kwargs)

    # ------------------------------------------------------------------
    # Public API (mirrors Mazemaker tool signatures)
    # ------------------------------------------------------------------
    def remember(self, content: str, category: str = "episodic",
                 metadata: Optional[dict] = None) -> str:
        """Store a memory and return its ID."""
        result = self._call(
            "neural_remember",
            content=content,
            category=category,
            metadata=metadata or {},
        )
        mem_id = result.get("id", "") if isinstance(result, dict) else str(result)
        logger.debug("Stored memory id=%s", mem_id)
        return mem_id

    def recall(self, query: str, top_k: int = 5) -> list[dict]:
        """Vector-similarity recall."""
        result = self._call("neural_recall", query=query, top_k=top_k)
        if isinstance(result, list):
            return result
        return result.get("memories", []) if isinstance(result, dict) else []

    def think(self, start_id: Optional[str] = None,
              query: Optional[str] = None,
              depth: int = 2, top_k: int = 5) -> list[dict]:
        """PPR spreading-activation recall."""
        kwargs: dict = {"depth": depth, "top_k": top_k}
        if start_id:
            kwargs["start_memory_id"] = start_id
        if query:
            kwargs["query"] = query
        result = self._call("neural_think", **kwargs)
        if isinstance(result, list):
            return result
        return result.get("memories", []) if isinstance(result, dict) else []

    def graph(self, memory_id: str) -> dict:
        """Return the graph neighbourhood of a memory node."""
        result = self._call("neural_graph", memory_id=memory_id)
        return result if isinstance(result, dict) else {}

    # ------------------------------------------------------------------
    # Higher-level social helpers
    # ------------------------------------------------------------------
    def recall_about_person(self, name: str, top_k: int = 5) -> list[dict]:
        return self.recall(f"{name} conversation context history", top_k=top_k)

    def recall_recent(self, session_id: str, top_k: int = 5) -> list[dict]:
        return self.recall(f"recent session {session_id}", top_k=top_k)

    def consolidate(self) -> None:
        """No-op placeholder; Mazemaker auto-consolidates via neural_remember."""
        return

    def format_context_block(self, memories: list[dict],
                              label: str = "MEMORY CONTEXT") -> str:
        if not memories:
            return ""
        lines = [f"[{label}]"]
        for i, m in enumerate(memories, 1):
            content = m.get("content", m.get("text", str(m)))
            lines.append(f"  {i}. {content}")
        return "\n".join(lines)
