"""Pacing simulation: how long a player takes to clear the haystack.

Models a player who clicks 3 times a second whenever they are at the haystack, walks to
the merchant when the bag is full (about 25 seconds a round trip), and always buys the
upgrade with the best rate gain per coin that they can afford. Reads the live numbers from
src/shared/Config.luau, so retuning Config retunes this.

    python3 dev/pacing.py            # free player
    python3 dev/pacing.py --robux    # with every pass and a permanent 2x speed power-up
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

CONFIG = (Path(__file__).resolve().parent.parent / "src" / "shared" / "Config.luau").read_text()
CLICKS_PER_SECOND = 3.0
TRIP_SECONDS = 25.0


def number(name: str) -> float:
    m = re.search(rf"^Config\.{name} = ([\d.]+)", CONFIG, re.M)
    assert m, name
    return float(m.group(1))


def rows(table: str) -> list[dict]:
    block = re.search(rf"^Config\.{table} = \{{(.*?)^\}}", CONFIG, re.M | re.S).group(1)
    out = []
    for line in block.splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue
        fields = dict(re.findall(r'(\w+) = ("[^"]*"|[\d.]+)', line))
        out.append({k: (v.strip('"') if v.startswith('"') else float(v)) for k, v in fields.items()})
    return out


class Player:
    def __init__(self, robux: bool):
        self.tools, self.bags, self.machines, self.perks = rows("Tools"), rows("Bags"), rows("Machines"), rows("Perks")
        self.tool, self.bag, self.perk = 0, 0, [0] * len(self.perks)
        self.owned = [0] * len(self.machines)
        self.coins, self.robux = 0.0, robux
        self.price = number("CoinsPerStraw")
        self.cooldown = number("SearchCooldown")

    def power(self, tool=None, perk=None):
        tool, perk = self.tool if tool is None else tool, self.perk if perk is None else perk
        p = self.tools[tool]["power"]
        return p * (1 + self.perks[0]["per_level"] * perk[0])

    def rate(self, tool=None, perk=None, owned=None):
        """Straws a second while searching, machines included."""
        perk = self.perk if perk is None else perk
        owned = self.owned if owned is None else owned
        cooldown = self.cooldown * (1 - self.perks[1]["per_level"] * perk[1])
        clicks = min(CLICKS_PER_SECOND, 1 / cooldown) * (2 if self.robux else 1)
        machines = sum(n * m["rate"] for n, m in zip(owned, self.machines))
        return self.power(tool, perk) * clicks + machines

    def options(self):
        """(cost, new rate, apply) for every upgrade available now."""
        out = []
        if self.tool + 1 < len(self.tools):
            t = self.tools[self.tool + 1]
            out.append((t["price"], self.rate(tool=self.tool + 1), lambda: setattr(self, "tool", self.tool + 1)))
        for i, perk in enumerate(self.perks):
            if self.perk[i] < perk["levels"]:
                new = list(self.perk)
                new[i] += 1
                scale = max(self.tools[self.tool]["price"], self.tools[1]["price"]) / self.tools[1]["price"]
                cost = perk["price"] * (perk["growth"] ** self.perk[i]) * scale
                out.append((cost, self.rate(perk=new), lambda i=i: self.perk.__setitem__(i, self.perk[i] + 1)))
        for i, m in enumerate(self.machines):
            if self.owned[i] < m["max"]:
                new = list(self.owned)
                new[i] += 1
                cost = m["price"] * (m["growth"] ** self.owned[i])
                out.append((cost, self.rate(owned=new), lambda i=i: self.owned.__setitem__(i, self.owned[i] + 1)))
        return out

    def shop(self):
        base = self.rate()
        while True:
            best = None
            for cost, new, apply in self.options():
                if cost <= self.coins and new > base:
                    gain = (new - base) / cost
                    if best is None or gain > best[0]:
                        best = (gain, apply, cost)
            if self.bag + 1 < len(self.bags) and self.bags[self.bag + 1]["price"] <= self.coins:
                trips = TRIP_SECONDS / (self.bags[self.bag]["size"] / base)  # seconds lost per second
                gain = base * trips * 0.5 / self.bags[self.bag + 1]["price"]
                if best is None or gain > best[0]:
                    best = (gain, lambda: setattr(self, "bag", self.bag + 1), self.bags[self.bag + 1]["price"])
            if best is None:
                return
            best[1]()
            self.coins -= best[2]
            base = self.rate()


def simulate(robux: bool, total: float | None = None) -> list[tuple[float, float]]:
    """Returns (hours, straws searched) checkpoints every 5% of the haystack."""
    total = total or number("TotalStraws")
    p = Player(robux)
    coin_mult = 2 if robux else 1
    searched, bag, t, marks, next_mark = 0.0, 0.0, 0.0, [], 0.05
    while searched < total:
        dt = 1.0
        straws = min(p.rate() * dt, total - searched)
        room = p.bags[p.bag]["size"] - bag
        if straws >= room:  # bag full: sell, buy, walk back
            straws = room
            bag = 0
            searched += straws
            p.coins += (p.bags[p.bag]["size"]) * p.price * coin_mult
            p.shop()
            t += TRIP_SECONDS
        else:
            bag += straws
            searched += straws
        t += dt
        while searched >= next_mark * total:
            marks.append((t / 3600, next_mark))
            next_mark += 0.05
    return marks


def main() -> None:
    robux = "--robux" in sys.argv
    marks = simulate(robux)
    print(("Robux" if robux else "Free") + " player, clearing the haystack:")
    for hours, share in marks:
        if abs(share * 20 - round(share * 20)) < 1e-6 and round(share * 20) % 4 == 0:
            print(f"  {share:4.0%} after {hours:5.1f} h")
    earliest = number("NeedleEarliest")
    first = next(h for h, s in marks if s >= earliest)
    print(f"  the needle is found between {first:.1f} h and {marks[-1][0]:.1f} h")


if __name__ == "__main__":
    main()
