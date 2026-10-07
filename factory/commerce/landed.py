"""South African local-stock unit economics (the `local_stock` business model).

Plain arithmetic on config/commerce.yaml: what one unit costs to land in the
fulfilment warehouse, what each order costs to send, what ads cost per sale,
the share of visitors who must buy just to break even, and the first stock
batch your cap buys. Every line carries its basis: evidence or assumption.

What-if calculator: python -m factory.commerce.landed --price 499 --cost 75 --weight 0.4
"""
from __future__ import annotations

import argparse
import math

from factory import config
from factory.smoke import budget

A = "assumption: config/commerce.yaml"


def retail_price(price_zar: float) -> float:
    """Round down to a shop price ending in 9 (R462 -> R449), never below R49."""
    return float(max(49, math.floor((price_zar + 1) / 50) * 50 - 1))


def _inbound(supplier: float, weight: float, rate: float, units: int) -> list[list]:
    """Per-unit costs from the supplier's door to the warehouse shelf, for a batch of `units`."""
    c = config.commerce()
    tax, i = c["tax"], c["inbound"]
    duty = supplier * rate  # SA charges duty on the supplier (FOB) price
    vat = 0.0 if tax["vat_registered"] else tax["vat"] * (supplier * (1 + tax["import_vat_uplift"]) + duty)
    storage = i["storage_zar_per_unit_month"] * c["stock"]["months_to_sell_batch"] / 2
    return [[f"Air freight, {weight:g} kg", round(weight * i["air_freight_zar_per_kg"], 2), A],
            [f"Customs duty {rate:.0%}", round(duty, 2), A],
            ["Import VAT" if vat else "Import VAT (reclaimed)", round(vat, 2), A],
            [f"Clearing R{i['clearing_zar_per_shipment']:,.0f} shared by {units} units",
             round(i["clearing_zar_per_shipment"] / units, 2), A],
            ["Warehouse receiving and storage", round(i["receiving_zar_per_unit"] + storage, 2), A]]


def first_batch(supplier: float, weight: float, rate: float, cap: float) -> tuple[int, float, list[list]]:
    """The largest first order, up to stock.first_batch_units, that fits the cap."""
    for units in range(int(config.commerce()["stock"]["first_batch_units"]), 0, -1):
        lines = _inbound(supplier, weight, rate, units)
        unit = supplier + sum(x[1] for x in lines)
        if units * unit <= cap:
            return units, unit, lines
    lines = _inbound(supplier, weight, rate, 1)
    return 0, supplier + sum(x[1] for x in lines), lines


def unit_economics(price_zar: float, supplier_zar: float, supplier_basis: str, weight_kg: float | None = None,
                   duty_category: str = "default", market: str | None = None) -> dict:
    c = config.commerce()
    market = market or c["market"]
    cap = float(config.settings()["caps"]["stock_batch_zar"])
    weight = float(weight_kg) if weight_kg and weight_kg > 0 else float(c["inbound"]["default_weight_kg"])
    category = duty_category if duty_category in c["duty"] else "default"
    units, landed, lines = first_batch(supplier_zar, weight, float(c["duty"][category]), cap)
    o, tax = c["per_order"], c["tax"]
    pct = o["payment_pct"] + o["store_fee_pct"] + o["returns_pct"]
    order = [["Pick and pack", float(o["pick_pack_zar"]), A], ["Packaging", float(o["packaging_zar"]), A],
             ["Courier to the buyer", float(o["courier_zar"]), A],
             [f"Payment, store fee and returns ({pct:.0%})", round(price_zar * pct, 2), A]]
    net = price_zar / (1 + tax["vat"]) if tax["vat_registered"] else price_zar
    left = net - landed - sum(x[1] for x in order)
    cpc = budget.cpc(market)
    avg, good = float(c["ads"]["conversion_average"]), float(c["ads"]["conversion_good"])
    return {"market": market, "price_zar": round(price_zar, 2), "net_price_zar": round(net, 2),
            "supplier_zar": round(supplier_zar, 2), "supplier_basis": supplier_basis, "weight_kg": weight,
            "weight_basis": "analyst estimate" if weight_kg and weight_kg > 0 else A, "duty_category": category,
            "landed_lines": [["Supplier price", round(supplier_zar, 2), supplier_basis]] + lines,
            "landed_zar": round(landed, 2), "order_lines": order,
            "per_order_zar": round(sum(x[1] for x in order), 2), "contribution_zar": round(left, 2),
            "cpc_zar": cpc, "break_even_conversion": round(cpc / left, 4) if left > 0 else None,
            "conversion_average": avg, "conversion_good": good,
            "profit_average_zar": round(left - cpc / avg, 2), "profit_good_zar": round(left - cpc / good, 2),
            "cac_good_zar": round(cpc / good, 2), "batch_units": units,
            "batch_zar": round(units * landed, 2), "batch_cap_zar": cap}


def gate_flags(u: dict) -> list[str]:
    """Reasons the Economics gate must kill a local-stock product."""
    c = config.commerce()
    top, need = float(c["gate"]["max_break_even_conversion"]), int(c["stock"]["min_first_batch_units"])
    out = []
    be = u["break_even_conversion"]
    if be is None:
        out.append(f"leaves R{u['contribution_zar']:,.0f} per order before any ads, so ads can never pay")
    elif be > top:
        out.append(f"{be:.1%} of visitors must buy just to break even (most allowed {top:.1%})")
    if u["batch_units"] < need:
        out.append(f"your R{u['batch_cap_zar']:,.0f} stock cap buys only {u['batch_units']} units at "
                   f"R{u['landed_zar']:,.0f} landed (a fair first batch is {need}+)")
    return out


def rand(v: float) -> str:
    return f"R{v:,.0f}" if v >= 0 else f"-R{-v:,.0f}"


def lines(u: dict) -> list[str]:
    """A plain-text breakdown for the calculator and `make dive`."""
    out = [f"Selling price R{u['price_zar']:,.0f} in {u['market']}; supplier price: {u['supplier_basis']}"]
    out += [f"  landed  {label:<42} R{v:>8,.2f}" for label, v, _ in u["landed_lines"]]
    out.append(f"  {'= landed cost per unit':<50} R{u['landed_zar']:>8,.2f}")
    out += [f"  order   {label:<42} R{v:>8,.2f}" for label, v, _ in u["order_lines"]]
    out.append(f"  {'= left per order before ads':<50} R{u['contribution_zar']:>8,.2f}")
    be = u["break_even_conversion"]
    out.append(f"  ads at R{u['cpc_zar']:g} a click: break even if {be:.1%} of visitors buy" if be
               else "  ads can never pay: nothing is left per order")
    out.append(f"  profit per order: {rand(u['profit_average_zar'])} if {u['conversion_average']:.1%} buy (average "
               f"store), {rand(u['profit_good_zar'])} if {u['conversion_good']:.1%} buy (top fifth of stores)")
    out.append(f"  first stock batch: {u['batch_units']} units for R{u['batch_zar']:,.0f} "
               f"(your cap R{u['batch_cap_zar']:,.0f})")
    return out


def main(argv: list[str] | None = None) -> None:
    p = argparse.ArgumentParser(description="What one product earns per order from a South African warehouse.")
    p.add_argument("--price", type=float, required=True, help="selling price in rand")
    p.add_argument("--cost", type=float, help="supplier price per unit in rand")
    p.add_argument("--usd", type=float, help="supplier price per unit in US dollars")
    p.add_argument("--weight", type=float, help="packed weight per unit in kg")
    p.add_argument("--category", default="default", help="duty: " + ", ".join(config.commerce()["duty"]))
    a = p.parse_args(argv)
    if a.cost is not None:
        sup, basis = a.cost, "you entered it"
    elif a.usd is not None:
        sup, basis = config.to_zar(a.usd, "USD"), f"you entered ${a.usd:g}"
    else:
        pct = float(config.business_models()["models"]["local_stock"]["unit_cost_pct"])
        sup, basis = a.price * pct, f"assumption: {pct:.0%} of price"
    u = unit_economics(a.price, sup, basis, a.weight, a.category)
    print("\n".join(lines(u)))
    flags = gate_flags(u)
    print("  commerce checks: " + ("pass" if not flags else "KILL: " + "; ".join(flags)))


if __name__ == "__main__":
    main()
