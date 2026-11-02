"""Unit economics of an AI-run service for one South African business client, per month.

Plain arithmetic on config/services.yaml and the model prices in settings.yaml:
the AI agent's tokens, QA reviews, channel fees, supervisor time, tools, payment
fees, and the cost to win the client spread over the months it stays. Every line
carries its basis (all assumptions until a client's real volumes replace them).

What-if: python -m factory.services.unit --model ai_support --price 2999 --volume 300
"""
from __future__ import annotations

import argparse

from factory import config, costs

A = "assumption: config/services.yaml"


def _ai_zar(model: str, tokens_in: float, tokens_out: float) -> float:
    return config.zar(costs.usd_for(model, int(tokens_in), int(tokens_out)))


CHANNELS = ("email", "whatsapp", "voice", "mixed")


def unit_economics(model: str, price_zar: float, volume: int | None = None, channel: str = "",
                   volume_basis: str = "") -> dict:
    """One client's month. `volume` (conversations or leads) comes from cited evidence or a
    what-if; without it the services.yaml default applies, labelled as an assumption."""
    c = config.services()
    ai, ch, ppl, oh = c["ai"], c["channels"], c["people"], c["overhead"]
    given = bool(volume and volume > 0)
    n = int(volume) if given else int(c["volume"][model])
    what = "leads" if model == "ai_followup" else "conversations"
    channel = channel if channel in CHANNELS else "mixed"
    agent = n * _ai_zar(ai["agent_model"], ai["tokens_in_per_task"], ai["tokens_out_per_task"])
    qa = n * ai["qa_share"] * _ai_zar(ai["qa_model"], ai["qa_tokens_in"], ai["qa_tokens_out"])
    if model == "ai_followup":
        per = ch["email_zar"] if channel == "email" else ch["whatsapp_template_zar"]
        chan = [[f"{'Email' if channel == 'email' else 'WhatsApp'} follow-ups, {ch['follow_up_messages']} per lead",
                 n * ch["follow_up_messages"] * per, A]]
        if channel == "voice":
            chan.append([f"Voice calls, {ch['voice_minutes_per_lead']} min per lead",
                         n * ch["voice_minutes_per_lead"] * ch["voice_zar_per_minute"], A])
    else:
        share = {"whatsapp": 1.0, "email": 0.0}.get(channel, float(ch["whatsapp_share"]))
        chan = [[f"WhatsApp replies, {share:.0%} of conversations", n * share * ch["whatsapp_reply_zar"], A]]
    rate, esc_share = float(ppl["supervisor_zar_per_hour"]), float(ppl["escalation_share"][model])
    cac_month = oh["cac_zar_per_client"] / oh["client_months"]
    lines = [[f"AI agent, {n} {what}", agent, "model prices x tokens (assumption: config/services.yaml)"],
             [f"QA reviews of {ai['qa_share']:.0%}", qa, A], *chan,
             [f"Supervisor takes {esc_share:.0%} of {what}", n * esc_share * ppl["minutes_per_escalation"] / 60 * rate, A],
             ["Supervisor spot checks, monthly client call", ppl["review_minutes_per_client"] / 60 * rate, A],
             ["Tools: helpdesk, numbers", float(oh["tools_zar_per_client"][model]), A],
             [f"Payment fees, {oh['payment_pct']:.0%}", price_zar * oh["payment_pct"], A],
             [f"Winning the client, R{oh['cac_zar_per_client']:,.0f} over {oh['client_months']} months", cac_month, A]]
    lines = [[label, round(float(v), 2), basis] for label, v, basis in lines]
    cost = round(sum(x[1] for x in lines), 2)
    return {"model": model, "price_zar": round(price_zar, 2), "volume": n, "what": what,
            "volume_basis": (volume_basis or "what-if") if given else A, "channel": channel,
            "lines": lines, "cost_zar": cost, "margin_zar": round(price_zar - cost, 2),
            "margin": round((price_zar - cost) / price_zar, 4) if price_zar else None,
            "cost_per_task_zar": round(cost / n, 2), "fees_zar": lines[-2][1], "cac_month_zar": round(cac_month, 2),
            "delivery_zar": round(cost - lines[-2][1] - lines[-1][1], 2)}  # one month's work: the pilot's cost


def lines(s: dict) -> list[str]:
    """A plain-text breakdown for the calculator and `make dive`."""
    out = [f"R{s['price_zar']:,.0f} a month per client, {s['volume']} {s['what']} ({s['volume_basis']}), "
           f"channel {s['channel']}"]
    out += [f"  cost    {label:<44} R{v:>9,.2f}" for label, v, _ in s["lines"]]
    out.append(f"  {'= cost per client per month':<52} R{s['cost_zar']:>9,.2f}")
    out.append(f"  {'= margin per client per month':<52} R{s['margin_zar']:>9,.2f}  ({s['margin']:.0%})")
    out.append(f"  cost per {s['what'][:-1]}: R{s['cost_per_task_zar']:,.2f}; a pilot month costs us "
               f"R{s['delivery_zar']:,.0f}")
    return out


def main(argv: list[str] | None = None) -> None:
    p = argparse.ArgumentParser(description="What one client of an AI-run service earns us per month.")
    p.add_argument("--model", default="ai_support", choices=["ai_support", "ai_followup"])
    p.add_argument("--price", type=float, required=True, help="monthly price in rand")
    p.add_argument("--volume", type=int, help="conversations or leads per month")
    p.add_argument("--channel", default="", help="email, whatsapp, voice or mixed")
    a = p.parse_args(argv)
    s = unit_economics(a.model, a.price, a.volume, a.channel)
    print("\n".join(lines(s)))
    floor = float(config.business_models()["models"][a.model]["min_margin"])
    print(f"  margin check: {'pass' if s['margin'] >= floor else 'KILL'} (minimum {floor:.0%})")


if __name__ == "__main__":
    main()
