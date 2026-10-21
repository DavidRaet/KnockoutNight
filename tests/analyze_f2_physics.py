"""Summarize recorded F2 trials; client clocks in column 8 are diagnostic only."""
import argparse
import json
import math
from pathlib import Path
from statistics import median


def motion_metrics(rows, origin):
    travel = max(math.hypot(row[1] - origin[0], row[3] - origin[2]) for row in rows)
    # Displacement exceeding endpoint speed integration exposes pauses/catch-up steps.
    excess = max((
        math.hypot(b[1] - a[1], b[3] - a[3])
        - max(math.hypot(a[4], a[6]), math.hypot(b[4], b[6])) * (b[0] - a[0])
        for a, b in zip(rows, rows[1:])
    ), default=0)
    return travel, max(0, excess)


def high_speed_pause(rows):
    longest = duration = 0
    for a, b in zip(rows, rows[1:]):
        stationary = math.hypot(b[1] - a[1], b[3] - a[3]) < .01
        fast = min(math.hypot(a[4], a[6]), math.hypot(b[4], b[6])) > 18
        duration = duration + b[0] - a[0] if stationary and fast else 0
        longest = max(longest, duration)
    return longest


def summarize(data):
    groups = {}
    for trial in data["trials"]:
        if not trial.get("server") or not trial.get("clients"):
            continue
        key = (trial["mode"], trial["probe"])
        group = groups.setdefault(key, {"n": 0, "corrections": 0, "failedChecks": [], "metrics": {}})
        group["n"] += 1
        group["corrections"] += trial["corrections"]
        group["failedChecks"].extend(f'{trial["id"]}:{name}' for name, passed in trial.get("checks", {}).items() if not passed)

        def record(name, value):
            group["metrics"].setdefault(name, []).append(value)

        record("rttMs", trial["rttMs"])
        if "minimumCredit" in trial:
            record("minimumCredit", trial["minimumCredit"])
        if "recoveredAt" in trial:
            record("recoveredSeconds", trial["recoveredAt"])
        origin = trial.get("origin", trial["server"][0][1:4])
        record("serverTravel", motion_metrics(trial["server"], origin)[0])
        for player, report in trial["clients"].items():
            role = "subject" if player == trial["player"] else "observer"
            rows = report["samples"]
            travel, excess = motion_metrics(rows, origin)
            record(role + "Travel", travel)
            record(role + "StepExcess", excess)
            record(role + "HighSpeedPauseSeconds", high_speed_pause(rows))
            if len(rows[0]) >= 8 and "startedAt" in trial:
                onset = next((row for row in rows if math.hypot(row[1] - origin[0], row[3] - origin[2]) >= .5), None)
                if onset:
                    record(role + "MotionSeconds", onset[7] - trial["startedAt"])
                if role == "subject" and "recovery" in trial:
                    release = trial["recovery"]["at"]
                    restored = next((row for row in rows if row[7] >= release and row[8] == 1 and row[9] == 0), None)
                    if restored:
                        record("releaseToMotorSeconds", restored[7] - release)
    summaries = []
    for (mode, probe), group in groups.items():
        metrics = group.pop("metrics")
        summaries.append(dict(mode=mode, probe=probe, **group,
                              ranges={name: dict(min=min(values), median=median(values), max=max(values))
                                      for name, values in metrics.items()}))
    return summaries


def self_test():
    smooth = [[0, 0, 0, 0, 50, 0, 0], [.1, 5, 0, 0, 50, 0, 0]]
    stalled = [[0, 0, 0, 0, 50, 0, 0], [.1, 0, 0, 0, 50, 0, 0], [.15, 7, 0, 0, 50, 0, 0]]
    assert motion_metrics(smooth, [0, 0, 0]) == (5, 0), "Smooth 50-stud/s motion must have no excess step"
    travel, excess = motion_metrics(stalled, [0, 0, 0])
    assert travel == 7 and abs(excess - 4.5) < 1e-9, "A pause then catch-up must expose its excess displacement"
    assert high_speed_pause(stalled) == .1, "Stationary high-speed samples must accumulate pause duration"
    assert high_speed_pause(smooth) == 0, "Continuous motion must not register a high-speed pause"
    print("PASS: F2 trajectory analysis self-check")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="*", type=Path)
    parser.add_argument("--self-test", action="store_true")
    options = parser.parse_args()
    if options.self_test:
        self_test()
    for path in options.paths:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
        print(json.dumps({"file": str(path), "passed": data["passed"],
                          "behaviorChecksPassed": data["behaviorChecksPassed"], "groups": summarize(data)}, indent=2))
