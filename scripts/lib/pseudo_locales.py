"""Deterministic pseudo-locales for layout and bidirectional testing."""

from __future__ import annotations


ACCENTS = str.maketrans("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", "àƀçđëƒğħïĵķľṁñöþɋŕšŧüṽẅẋÿžÀƁÇĐËƑĞĦÏĴĶĽṀÑÖÞɊŔŠŦÜṼẄẊŸŽ")


def pseudo_long(value: str) -> str:
    transformed = value.translate(ACCENTS)
    padding = " · expanded" if len(value) < 28 else " · expanded localized content"
    return f"［{transformed}{padding}］"


def pseudo_rtl(value: str) -> str:
    return f"\u2067⟦{value.translate(ACCENTS)}⟧\u2069"
