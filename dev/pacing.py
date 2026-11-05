"""Pacing simulation: how long a player takes to harvest their pile.

Models a player who clicks 3 times a second while harvesting, walks to the merchant when the
tool is full (TRIP_SECONDS for the round trip, climbing included), and always buys the upgrade
with the best rate gain per coin it can afford. Machines need generator power, so a machine's
cost includes the power it needs. Machines fill the silo, sold on every trip. Reads the live
numbers from src/shared/Config.luau, so retuning Config retunes this.

The needle hides deep in the upper heap and machines peel the heap from the outside in, so
without climbing a player reaches it only after most of the heap (needle_share() says how
much on average). Climbing up and digging straight in is the shortcut that finds it sooner.

    python3 dev/pacing.py            # free player
    python3 dev/pacing.py --robux    # with every pass and a permanent 2x speed power-up
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

CONFIG = (Path(__file__).resolve().parent.parent / "src" / "shared" / "Config.luau").read_text()
CLICKS_PER_SECOND = 3.0
TRIP_SECONDS = 45.0
BUILD_COINS = 60000  # stairs, landings and elevators bought along the way


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


def layout() -> dict:
    """Mirror of src/shared/Layout.luau: clump cells bottom to top, the machines' order and
    the needle's hiding places."""
    import math
    s, n_layers = number("ClumpSize"), int(number("PileLayers"))
    r0, r1, curve, clumps = number("PileRadiusBottom"), number("PileRadiusTop"), number("PileCurve"), int(number("Clumps"))
    dome = number("PileDome")
    height = [float(v) for v in re.search(r"^Config\.NeedleHeight = \{ ([\d.]+), ([\d.]+) \}", CONFIG, re.M).groups()]
    core_max = number("NeedleCore")
    layers, radius, total = [], [], 0
    for i in range(n_layers):
        r = r1 + (r0 - r1) * max(0.0, 1 - (i / (n_layers - 1)) ** dome) ** curve
        radius.append(r)
        n = math.floor(r / s)
        layer = [(gx, i, gz, gx * gx + gz * gz) for gx in range(-n, n + 1) for gz in range(-n, n + 1) if (gx * s) ** 2 + (gz * s) ** 2 <= r * r]
        total += len(layer)
        layers.append(layer)
    excess = total - clumps
    for layer in layers:
        if excess <= 0:
            break
        layer.sort(key=lambda c: (-c[3], c[0], c[2]))
        cut = min(excess, len(layer) // 4)
        del layer[:cut]
        excess -= cut
    cells, core = [], []
    for layer in layers:
        layer.sort(key=lambda c: (c[0], c[2]))
        for c in layer:
            cells.append((c[0] * s, c[1] * s + s / 2, c[2] * s, c[1]))
            core.append(min(1.0, max(0.0, math.sqrt(c[3]) * s / max(radius[c[1]], s))))
    order = sorted(range(len(cells)), key=lambda i: (-math.floor(core[i] * 8), cells[i][3], i))
    spots = [i for i in range(len(cells)) if height[0] * n_layers <= cells[i][3] <= height[1] * n_layers and core[i] <= core_max]
    return {"cells": cells, "core": core, "order": order, "spots": spots}


def needle_share() -> float:
    """How much of the heap the machines clear, on average, before reaching the needle."""
    lay = layout()
    rank = {c: i for i, c in enumerate(lay["order"])}
    return sum(rank[c] + 1 for c in lay["spots"]) / len(lay["spots"]) / len(lay["cells"])


class Player:
    def __init__(self, robux: bool):
        self.tools, self.silos, self.machines = rows("Tools"), rows("Silos"), rows("Machines")
        self.generators, self.perks = rows("Generators"), rows("Perks")
        self.tool, self.silo, self.perk = 0, 0, [0] * len(self.perks)
        self.owned = [0] * len(self.machines)
        self.gens = [0] * len(self.generators)
        self.coins, self.robux = 0.0, robux
        self.cooldown = number("SearchCooldown")
        self.trucks_def = rows("Trucks")
        self.trucks = [0] * len(self.trucks_def)
        self.buckets = rows("Buckets")
        self.bucket = 0
        self.build_left = BUILD_COINS

    def power_made(self, gens=None):
        gens = self.gens if gens is None else gens
        return sum(n * g["power"] for n, g in zip(gens, self.generators))

    def click_rate(self, tool=None, perk=None):
        tool, perk = self.tool if tool is None else tool, self.perk if perk is None else perk
        power = self.tools[tool]["power"] * (1 + self.perks[0]["per_level"] * perk[0])
        cooldown = self.cooldown * (1 - self.perks[1]["per_level"] * perk[1])
        return power * min(CLICKS_PER_SECOND, 1 / cooldown) * (2 if self.robux else 1)

    def machine_rate(self, owned=None, gens=None):
        owned = self.owned if owned is None else owned
        draw = sum(n * m["draw"] for n, m in zip(owned, self.machines))
        rate = sum(n * m["rate"] for n, m in zip(owned, self.machines)) * (2 if self.robux else 1)
        made = self.power_made(gens)
        return rate * (min(1.0, made / draw) if draw > 0 else 0)

    def haul(self, trucks=None):
        """Straws a second the trader and the trucks sell from the basket."""
        trucks = self.trucks if trucks is None else trucks
        return number("TraderRate") + sum(n * t["rate"] for n, t in zip(trucks, self.trucks_def))

    def income(self, **kw):
        """Straws a second that turn into coins: what you make, up to what is hauled."""
        return min(self.rate(**kw), self.haul(kw.get("trucks")))

    def rate(self, **kw):
        """Average straws a second, counting the time lost walking to the merchant."""
        click = self.click_rate(kw.get("tool"), kw.get("perk"))
        tool = self.tool if kw.get("tool") is None else kw["tool"]
        bucket = self.bucket if kw.get("bucket") is None else kw["bucket"]
        fill = (self.tools[tool]["capacity"] + self.buckets[bucket]["capacity"]) / click
        trips = 0 if self.robux else TRIP_SECONDS / (fill + TRIP_SECONDS)
        machines = self.machine_rate(kw.get("owned"), kw.get("gens"))
        silo = self.silos[self.silo]["size"]
        machines = min(machines, silo / (fill + TRIP_SECONDS))  # the silo caps what waits for a trip
        return click * (1 - trips) + machines

    def options(self):
        out = []
        if self.tool + 1 < len(self.tools):
            out.append((self.tools[self.tool + 1]["price"], {"tool": self.tool + 1}, lambda: self._set_tool()))
        for i, perk in enumerate(self.perks):
            if self.perk[i] < perk["levels"]:
                new = list(self.perk)
                new[i] += 1
                scale = max(self.tools[self.tool]["price"], self.tools[1]["price"]) / self.tools[1]["price"]
                cost = perk["price"] * perk["growth"] ** self.perk[i] * scale
                out.append((cost, {"perk": new}, lambda i=i: self.perk.__setitem__(i, self.perk[i] + 1)))
        for i, m in enumerate(self.machines):
            if self.owned[i] < m["max"]:
                new = list(self.owned)
                new[i] += 1
                out.append((m["price"], {"owned": new}, lambda i=i: self.owned.__setitem__(i, self.owned[i] + 1)))
        for i, g in enumerate(self.generators):
            if self.gens[i] < g["max"]:
                new = list(self.gens)
                new[i] += 1
                out.append((g["price"], {"gens": new}, lambda i=i: self.gens.__setitem__(i, self.gens[i] + 1)))
        for i, t in enumerate(self.trucks_def):
            if self.trucks[i] < t["max"]:
                new = list(self.trucks)
                new[i] += 1
                out.append((t["price"], {"trucks": new}, lambda i=i: self.trucks.__setitem__(i, self.trucks[i] + 1)))
        if self.bucket + 1 < len(self.buckets):
            out.append((self.buckets[self.bucket + 1]["price"], {"bucket": self.bucket + 1}, lambda: setattr(self, "bucket", self.bucket + 1)))
        if self.silo + 1 < len(self.silos):
            out.append((self.silos[self.silo + 1]["price"], {"silo": True}, lambda: setattr(self, "silo", self.silo + 1)))
        return out

    def _set_tool(self):
        self.tool += 1
        self.perk = [0] * len(self.perks)

    def gain(self, change):
        if change.get("silo"):
            self.silo += 1
            new = self.income()
            self.silo -= 1
            return new
        if "owned" in change:  # a machine with no power is worth what it would make powered
            powered = [g + 10 for g in self.gens]
            return min(self.rate(owned=change["owned"], gens=powered) - self.rate(gens=powered) + self.rate(), self.haul())
        return self.income(**change)

    def shop(self):
        if self.build_left > 0:  # some coins always go on stairs and lifts
            spend = min(self.build_left, self.coins * 0.3)
            self.coins -= spend
            self.build_left -= spend
        base = self.income()
        while True:
            best = None
            for cost, change, apply in self.options():
                if cost <= self.coins:
                    gain = (self.gain(change) - base) / cost
                    if gain > 0 and (best is None or gain > best[0]):
                        best = (gain, apply, cost)
            if best is None:
                return
            best[1]()
            self.coins -= best[2]
            base = self.income()


def simulate(robux: bool) -> list[tuple[float, float]]:
    """Returns (hours, share of the pile harvested) every 5%."""
    total = number("TotalStraws")
    p = Player(robux)
    coin_mult = 2 if robux else 1
    searched, basket, t, marks, next_mark = 0.0, 0.0, 0.0, [], 0.05
    while searched < total and t < 400 * 3600:
        straws = min(p.rate() * 60, total - searched)  # one minute at a time
        searched += straws
        basket += straws  # it all waits in the basket, sold as fast as it's hauled
        sold = min(basket, p.haul() * 60)
        basket -= sold
        p.coins += sold * number("CoinsPerStraw") * coin_mult
        p.shop()
        t += 60
        while searched >= next_mark * total - 1e-6 and next_mark <= 1.0001:
            marks.append((t / 3600, round(next_mark, 2)))
            next_mark += 0.05
    return marks


def needle_hours(marks) -> float:
    share = needle_share()
    return next(h for h, s in marks if s >= share - 0.025)


def main() -> None:
    robux = "--robux" in sys.argv
    marks = simulate(robux)
    print(("Robux" if robux else "Free") + " player, harvesting the pile:")
    for hours, share in marks:
        if round(share * 100) % 20 == 0:
            print(f"  {share:4.0%} after {hours:5.1f} h")
    share = needle_share()
    found = needle_hours(marks)
    print(f"  the needle is {share:.0%} of the way in: found after about {found:.1f} h on average without climbing (the pile is cleared at {marks[-1][0]:.1f} h)")


if __name__ == "__main__":
    main()
