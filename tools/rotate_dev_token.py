"""Rotates the secretary auth token stored in the local dev database.

The committed db.sqlite3 exposed a real phone number and a live bearer token on
a public repository, so that credential has to stop working. This rewrites the
token for every secretary row with a fresh random value.

Run from the repository root:
    python tools/rotate_dev_token.py
"""
import secrets
import sqlite3
import sys
from pathlib import Path

DB = Path("django-backend/tapverify/db.sqlite3")


def main() -> int:
    if not DB.exists():
        print(f"no database at {DB}, nothing to rotate")
        return 0

    conn = sqlite3.connect(DB)
    try:
        rows = conn.execute("SELECT id, phone FROM core_secretary").fetchall()
        if not rows:
            print("no secretary rows, nothing to rotate")
            return 0
        # auth_token is unique, so every row needs its own value.
        for row_id, phone in rows:
            conn.execute(
                "UPDATE core_secretary SET auth_token = ? WHERE id = ?",
                (secrets.token_hex(32), row_id),
            )
            print(f"rotated token for secretary id={row_id} phone={phone}")
        conn.commit()
    finally:
        conn.close()

    print("old tokens are now invalid, log in again to get a new one")
    return 0


if __name__ == "__main__":
    sys.exit(main())
