"""Email delivery for Warden reports and alerts, using the standard library (smtplib).

Optional: without SMTP settings in .env nothing is sent, and reports still
appear on the dashboard and in data/reports/. Settings:
SMTP_HOST, SMTP_PORT (587 STARTTLS or 465 SSL), SMTP_USER, SMTP_PASSWORD,
REPORT_EMAIL_TO, REPORT_EMAIL_FROM (defaults to SMTP_USER).
"""
from __future__ import annotations

import logging
import smtplib
from email.message import EmailMessage

from factory import config
from factory.models import session

log = logging.getLogger("factory.warden.mailer")


def configured() -> bool:
    return bool(config.env("SMTP_HOST") and config.env("REPORT_EMAIL_TO"))


def send(subject: str, text: str, html: str | None = None) -> bool:
    if not configured():
        return False
    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = config.env("REPORT_EMAIL_FROM") or config.env("SMTP_USER") or "warden@localhost"
    msg["To"] = config.env("REPORT_EMAIL_TO")
    msg.set_content(text)
    if html:
        msg.add_alternative(html, subtype="html")
    host, port = config.env("SMTP_HOST"), int(config.env("SMTP_PORT", "587"))
    try:
        if port == 465:
            server = smtplib.SMTP_SSL(host, port, timeout=30)
        else:
            server = smtplib.SMTP(host, port, timeout=30)
            server.starttls()
        with server:
            if config.env("SMTP_USER"):
                server.login(config.env("SMTP_USER"), config.env("SMTP_PASSWORD"))
            server.send_message(msg)
        return True
    except (OSError, smtplib.SMTPException) as e:
        log.error("email failed: %s", e)
        return False


def alert(needs_you: list) -> bool:
    """One email listing every needs-you incident not emailed before."""
    fresh = [i for i in needs_you if not i.emailed]
    if not fresh or not configured():
        return False
    lines = [f"- {i.detail}\n  What the Warden did: {i.action}" for i in fresh]
    ok = send(f"Venture Factory: {len(fresh)} thing{'s' if len(fresh) != 1 else ''} need you",
              "The Warden needs a human for:\n\n" + "\n".join(lines) + "\n\nOpen the dashboard to act.")
    if ok:
        from factory.warden.tables import Incident
        with session() as s:
            for i in fresh:
                row = s.get(Incident, i.id)
                row.emailed = True
                s.add(row)
            s.commit()
    return ok
