#!/usr/bin/env python3
"""Validate catalog/catalog.json against the rules in docs/CARD_CATALOG.md.

Usage:
    python3 catalog/validate.py [path/to/catalog.json] [--previous path/to/old.json]

Exits non-zero on any error. Run before every push to main (GitHub Pages publishes main).
"""
import argparse
import json
import re
import sys
from pathlib import Path

SUPPORTED_SCHEMA = 1
CATEGORIES = {
    "dining", "groceries", "gas", "ev_charging", "flights", "hotels", "travel_other", "transit",
    "streaming", "drugstores", "online_retail", "entertainment", "home_improvement", "utilities", "other",
}
NETWORKS = {"visa", "mastercard", "amex", "discover"}
CONDITIONS = {"booked_via_portal", "requires_activation", "booked_direct_or_portal", "us_only", "brand_only"}
CREDIT_PERIODS = {"monthly", "quarterly", "semiannual", "annual", "multi_year"}
CAP_PERIODS = {"monthly", "quarterly", "annual"}
RESET_BASES = {"calendar", "cardmember_year"}
SNAKE = re.compile(r"^[a-z0-9]+(_[a-z0-9]+)*$")
QUARTER = re.compile(r"^\d{4}Q[1-4]$")
DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def is_num(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def check_multiplier(m, where, errors):
    if not is_num(m.get("rate")) or m["rate"] <= 0:
        errors.append(f"{where}: rate must be a positive number")
    rotating = m.get("rotating")
    if rotating is not None:
        if "category" in m:
            errors.append(f"{where}: rotating rows must not have a category")
        quarters = rotating.get("quarters") if isinstance(rotating, dict) else None
        if not isinstance(quarters, dict) or not quarters:
            errors.append(f"{where}: rotating.quarters must be a non-empty object")
        else:
            for q, cats in quarters.items():
                if not QUARTER.match(q):
                    errors.append(f"{where}: bad quarter key {q!r} (want YYYYQn)")
                if not isinstance(cats, list) or not cats or not set(cats) <= CATEGORIES:
                    errors.append(f"{where}: quarter {q} has unknown or empty categories {cats!r}")
    elif m.get("category") not in CATEGORIES:
        errors.append(f"{where}: unknown category {m.get('category')!r}")

    cond = m.get("condition")
    if cond is not None and cond not in CONDITIONS:
        errors.append(f"{where}: unknown condition {cond!r}")
    if cond == "brand_only" and not m.get("brand"):
        errors.append(f"{where}: brand_only requires brand")

    cap = m.get("cap")
    if cap is not None:
        if not isinstance(cap, dict) or not is_num(cap.get("amount")) or cap.get("period") not in CAP_PERIODS:
            errors.append(f"{where}: cap needs a numeric amount and period in {sorted(CAP_PERIODS)}")
        if not is_num(m.get("afterCapRate")):
            errors.append(f"{where}: cap requires a numeric afterCapRate")

    if m.get("userSelectable") or m.get("autoTopCategory"):
        elig = m.get("eligibleCategories")
        if not isinstance(elig, list) or not elig or not set(elig) <= CATEGORIES:
            errors.append(f"{where}: userSelectable/autoTopCategory requires valid eligibleCategories")


def check_credit(c, where, errors):
    if not isinstance(c.get("id"), str) or not SNAKE.match(c["id"]):
        errors.append(f"{where}: id must be snake_case")
    if not isinstance(c.get("name"), str) or not c["name"]:
        errors.append(f"{where}: name required")
    if not is_num(c.get("amount")) or c["amount"] <= 0:
        errors.append(f"{where}: amount must be a positive number")
    if c.get("period") not in CREDIT_PERIODS:
        errors.append(f"{where}: unknown period {c.get('period')!r}")
    if c.get("period") == "multi_year" and not (isinstance(c.get("periodYears"), int) and c["periodYears"] > 1):
        errors.append(f"{where}: multi_year requires periodYears > 1")
    if c.get("resetBasis") not in RESET_BASES:
        errors.append(f"{where}: unknown resetBasis {c.get('resetBasis')!r}")
    if "requiresEnrollment" in c and not isinstance(c["requiresEnrollment"], bool):
        errors.append(f"{where}: requiresEnrollment must be a bool")


def check_card(card, currency_ids, errors):
    cid = card.get("id", "<missing id>")
    where = f"card {cid}"
    if not isinstance(card.get("id"), str) or not SNAKE.match(card["id"]):
        errors.append(f"{where}: id must be snake_case")
    if not isinstance(card.get("revision"), int) or card["revision"] < 1:
        errors.append(f"{where}: revision must be an int >= 1")
    for field in ("issuer", "name"):
        if not isinstance(card.get(field), str) or not card[field]:
            errors.append(f"{where}: {field} required")
    if card.get("network") not in NETWORKS:
        errors.append(f"{where}: unknown network {card.get('network')!r}")
    if not is_num(card.get("annualFee")) or card["annualFee"] < 0:
        errors.append(f"{where}: annualFee must be a number >= 0")
    if card.get("rewardCurrency") not in currency_ids:
        errors.append(f"{where}: rewardCurrency {card.get('rewardCurrency')!r} not in currencies")
    if not isinstance(card.get("lastVerified"), str) or not DATE.match(card["lastVerified"]):
        errors.append(f"{where}: lastVerified must be YYYY-MM-DD")
    if not isinstance(card.get("retired"), bool):
        errors.append(f"{where}: retired must be a bool")

    membership = card.get("requiredMembership")
    if membership is not None:
        if not isinstance(membership, dict) or not membership.get("name") or not (
            is_num(membership.get("monthlyFee")) or is_num(membership.get("annualFee"))
        ):
            errors.append(f"{where}: requiredMembership needs name and monthlyFee and/or annualFee")

    multipliers = card.get("multipliers")
    if not isinstance(multipliers, list):
        errors.append(f"{where}: multipliers must be a list")
        multipliers = []
    unconditional = {}
    for i, m in enumerate(multipliers):
        check_multiplier(m, f"{where} multiplier[{i}]", errors)
        if "rotating" not in m and m.get("condition") is None and not m.get("userSelectable"):
            cat = m.get("category")
            unconditional[cat] = unconditional.get(cat, 0) + 1
    if unconditional.get("other", 0) != 1:
        errors.append(f"{where}: needs exactly one unconditional 'other' row (has {unconditional.get('other', 0)})")
    for cat, n in unconditional.items():
        if n > 1:
            errors.append(f"{where}: {n} unconditional rows for category {cat!r}")

    credits = card.get("credits")
    if not isinstance(credits, list):
        errors.append(f"{where}: credits must be a list")
        credits = []
    seen = set()
    for i, c in enumerate(credits):
        check_credit(c, f"{where} credit[{i}]", errors)
        if c.get("id") in seen:
            errors.append(f"{where}: duplicate credit id {c.get('id')!r}")
        seen.add(c.get("id"))


def validate(catalog, previous=None):
    errors = []
    if not isinstance(catalog, dict):
        return ["top level must be an object"]
    if catalog.get("schemaVersion") != SUPPORTED_SCHEMA:
        errors.append(f"schemaVersion must be {SUPPORTED_SCHEMA}")
    if not isinstance(catalog.get("catalogVersion"), int):
        errors.append("catalogVersion must be an int (YYYYMMDDnn)")
    if not isinstance(catalog.get("publishedAt"), str):
        errors.append("publishedAt required")

    currencies = catalog.get("currencies")
    if not isinstance(currencies, list) or not currencies:
        errors.append("currencies must be a non-empty list")
        currencies = []
    currency_ids = {c.get("id") for c in currencies if isinstance(c, dict) and c.get("name")}
    if len(currency_ids) != len(currencies):
        errors.append("every currency needs a unique id and a name")

    cards = catalog.get("cards")
    if not isinstance(cards, list):
        return errors + ["cards must be a list"]
    ids = [c.get("id") for c in cards]
    for dup in {i for i in ids if ids.count(i) > 1}:
        errors.append(f"duplicate card id {dup!r}")
    for card in cards:
        check_card(card, currency_ids, errors)

    if previous is not None:
        if isinstance(catalog.get("catalogVersion"), int) and catalog["catalogVersion"] <= previous.get("catalogVersion", 0):
            errors.append(f"catalogVersion must increase (previous {previous.get('catalogVersion')})")
        missing = {c.get("id") for c in previous.get("cards", [])} - set(ids)
        for cid in sorted(missing):
            errors.append(f"card {cid!r} was removed; mark it retired instead")
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("path", nargs="?", default=str(Path(__file__).with_name("catalog.json")))
    parser.add_argument("--previous", help="previously published catalog.json, for version and removal checks")
    args = parser.parse_args()

    try:
        catalog = json.loads(Path(args.path).read_text())
        previous = json.loads(Path(args.previous).read_text()) if args.previous else None
    except (OSError, json.JSONDecodeError) as e:
        print(f"ERROR: {e}")
        return 1

    errors = validate(catalog, previous)
    for e in errors:
        print(f"ERROR: {e}")
    if errors:
        print(f"{len(errors)} error(s)")
        return 1
    print(f"OK: {len(catalog['cards'])} cards, catalogVersion {catalog['catalogVersion']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
