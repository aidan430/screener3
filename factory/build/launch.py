"""Fund launch: the human's second money approval for a certified niche (tower 6).

Nothing is bought automatically. Launching creates the Venture row (a mine at
the Market, status building), prepares the venture folder for the Claude Code
session that builds it, and returns the shopping list from the Dossier. For a
local-stock product the button reads FUND STOCK, and the folder gets
stock/first-order.md: the draft first order for the owner to place. A service for
businesses gets client/first-client.md: what to sign and set up before the first
client's pilot.
"""
from __future__ import annotations

import subprocess
from pathlib import Path

from sqlmodel import select

from factory import config
from factory.models import Build, Card, Dossier, SmokeTest, Venture, session, utcnow
from factory.training.tables import Squad

GITIGNORE = ".env\n.venv/\n__pycache__/\ndata/\n"


def shopping_list(card_id: int) -> tuple[list[list], float]:
    with session() as s:
        d = s.exec(select(Dossier).where(Dossier.card_id == card_id).order_by(Dossier.id.desc())).first()
    lines = [x for x in (d.j("capital_lines") if d else []) if not x[0].startswith("Smoke test")]
    return lines, round(sum(x[1] for x in lines), 2)


def fund_label(d: Dossier | None) -> str:
    """Tower 6's button: a local-stock product buys its first stock, anything else launches."""
    return "FUND STOCK" if d is not None and d.j("unit") else "FUND LAUNCH"


def first_order(folder: Path, name: str, u: dict) -> Path:
    """The draft first stock order. Nothing is ordered: the owner places it."""
    c = config.commerce()
    n = int(c["stock"]["samples"])
    rows = [f"| {label} | R{v:,.2f} | {basis} |" for label, v, basis in u["landed_lines"] + u["order_lines"]]
    text = "\n".join([
        f"# First stock order: {name}", "",
        "Nothing has been ordered or paid. This is the draft for you to place yourself.", "",
        f"- Units: {u['batch_units']} (your cap R{u['batch_cap_zar']:,.0f}); about R{u['batch_zar']:,.0f} landed",
        f"- Supplier price: R{u['supplier_zar']:,.2f} a unit ({u['supplier_basis']})",
        f"- Packed weight: {u['weight_kg']:g} kg ({u['weight_basis']})",
        f"- Duty category: {u['duty_category']}; your clearing agent confirms the tariff code",
        "- Ship to: your fulfilment warehouse's inbound address, by consolidated air cargo", "",
        "## Before you pay", "",
        f"1. Order {n} samples first; check quality, packaging and the real packed weight.",
        "2. Sign up with a fulfilment warehouse (for example Parcel Ninja) and get its inbound address.",
        "3. Check the product needs no ICASA, NRCS or SAHPRA approval. The Craft gate judged the description,",
        "   not the product itself.",
        "4. Ask the supplier for a commercial invoice with the HS (tariff) code.",
        "5. Tell the warehouse the shipment is coming (an advance shipping notice).", "",
        "## The numbers behind it", "", "| Line | Rand | Basis |", "|---|---|---|", *rows, "",
        f"Each order leaves about R{u['contribution_zar']:,.0f} before ads. At R{u['cpc_zar']:g} a click it breaks even "
        f"when {u['break_even_conversion']:.1%} of visitors buy." if u.get("break_even_conversion") else
        "Nothing is left per order before ads; do not order before the numbers change."])
    path = folder / "stock" / "first-order.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text + "\n")
    return path


def first_client(folder: Path, name: str, sv: dict) -> Path:
    """The checklist for the first client of a service. Nothing is signed or sent: the owner does it."""
    rows = [f"| {label} | R{v:,.2f} | {basis} |" for label, v, basis in sv["lines"]]
    text = "\n".join([
        f"# First client: {name}", "",
        "Nothing has been signed, sent or bought. This is your checklist; a person does every step.", "",
        f"- Offer: R{sv['price_zar']:,.0f} a month for about {sv['volume']} {sv['what']} ({sv['channel']} channel)",
        f"- Cost to serve one client: about R{sv['cost_zar']:,.0f} a month; margin R{sv['margin_zar']:,.0f}",
        f"- The free pilot month costs about R{sv['delivery_zar']:,.0f} to run", "",
        "## Before the first conversation", "",
        "1. Register the company (CIPC) and register its information officer with the Information Regulator",
        "   (POPIA section 55).",
        "2. Have a lawyer check the service agreement and the operator agreement. The client is the responsible",
        "   party for its customers' data and you are its operator (POPIA sections 20 and 21): you act only on its",
        "   instructions, keep the data secure and report any breach to it at once.",
        "3. Agree the service levels in writing: hours covered, reply times, what the agents may and may not say,",
        "   and who at the client takes each hand-over.",
        "4. Collect the client's FAQs, prices and policies; the squad answers only from these.",
        "5. Follow-up work: get proof that each lead asked to be contacted, the client's contact hours, and an",
        "   opt-out line for every message (POPIA section 69, the Consumer Protection Act). No cold lists.",
        "6. Call recording: tell every caller at the start (RICA). Voice needs a voice-AI provider, which is",
        "   not connected: it is a new tool you would approve first.",
        "7. Run 20 test conversations with the client watching before go-live.", "",
        "## The numbers behind it", "", "| Line | Rand a month | Basis |", "|---|---|---|", *rows, "",
        "Every number here is an assumption until a month of the client's real volumes replaces it."])
    path = folder / "client" / "first-client.md"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text + "\n")
    return path


def launch(card_id: int) -> dict:
    with session() as s:
        card = s.get(Card, card_id)
        if not card or card.status != "certified":
            return {"ok": False, "message": "Only a niche whose squad is certified can be launched."}
        squad = s.exec(select(Squad).where(Squad.card_id == card_id, Squad.status == "certified")
                       .order_by(Squad.id.desc())).first()
        t = s.exec(select(SmokeTest).where(SmokeTest.card_id == card_id)).first()
        b = s.exec(select(Build).where(Build.smoke_id == t.id)).first()
        d = Path(squad.folder)
        d.mkdir(parents=True, exist_ok=True)
        (d / ".gitignore").write_text(GITIGNORE)
        (d / "README.md").write_text(f"# {t.name}\n\nBuilt from CLAUDE.md by a Claude Code session. "
                                     "The certified squad's instructions are in squad/.\n")
        if not (d / ".git").exists():
            subprocess.run(["git", "init", "-q", str(d)], check=False)
        dossier = s.exec(select(Dossier).where(Dossier.card_id == card_id).order_by(Dossier.id.desc())).first()
        unit = dossier.j("unit") if dossier else {}
        service = dossier.j("service") if dossier else {}
        order = first_order(d, t.name, unit) if unit else None
        client = first_client(d, t.name, service) if service else None
        v = s.exec(select(Venture).where(Venture.slug == t.slug)).first() or Venture(
            slug=t.slug, name=t.name, price_label=t.price_label, build_id=b.id if b else None)
        squad.status, squad.launched_at = "launched", utcnow()
        card.status = "building"
        if b:
            b.status = "launched"
            s.add(b)
        s.add(v)
        s.add(squad)
        s.add(card)
        s.commit()
    lines, total = shopping_list(card_id)
    items = "\n".join(f"- {x[0]}: R{x[1]:,.0f}" for x in lines) or "- (no capital lines in the Dossier)"
    first = "Stock approved" if order else "Launch approved"
    stock = (f"First: open {order} (samples, a fulfilment warehouse, then the first order).\n" if order else
             f"First: open {client} (company, contracts and consent before the first client's pilot).\n" if client
             else "")
    return {"ok": True, "message": (
        f"{first} for {t.name}. Nothing is bought automatically. Your shopping list (R{total:,.0f}):\n"
        f"{items}\n{stock}Then start the build: cd {d} && claude \"Read CLAUDE.md and build it.\"\n"
        "The certified squad's instructions are in squad/; Operations runs them from Phase 5.")}
