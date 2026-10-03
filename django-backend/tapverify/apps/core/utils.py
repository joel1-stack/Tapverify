"""Kenyan phone number helpers."""
import re


def normalize_ke_phone(raw):
    """Normalize a Kenyan phone number to +2547XXXXXXXX form.

    Accepts: 0712345678, 712345678, 254712345678, +254712345678,
    and the same patterns for 01XXXXXXXX lines.
    Returns '' when the input cannot be parsed.
    """
    if not raw:
        return ''
    digits = re.sub(r'\D', '', raw)
    if digits.startswith('254') and len(digits) == 12:
        national = digits[3:]
    elif digits.startswith('0') and len(digits) == 10:
        national = digits[1:]
    elif len(digits) == 9 and digits[0] in '17':
        national = digits
    else:
        return ''
    return f'+254{national}'


def is_valid_ke_phone(raw):
    return bool(normalize_ke_phone(raw))


def parse_member_line(line):
    """Parse one pasted line into (name, phone).

    Accepts: '0712345678', 'Mary Wanjiku, 0712345678',
    'Mary Wanjiku 0712345678', '0712345678 Mary Wanjiku'.
    Returns None when no valid phone is present.
    """
    line = (line or '').strip()
    if not line:
        return None
    phone = ''
    name_parts = []
    for token in re.split(r'[,\t]', line):
        token = token.strip()
        if not token:
            continue
        # A token containing letters is a name (+ maybe a phone inside it),
        # never a bare phone - normalize strips non-digits, which would
        # otherwise swallow "John Otieno 0722000002" as one phone.
        if not re.search(r'[A-Za-z]', token):
            candidate = normalize_ke_phone(token)
            if candidate and not phone:
                phone = candidate
                continue
        # handle 'Mary 0712345678' inside a single token
        words = token.split()
        rest = []
        for w in words:
            candidate = normalize_ke_phone(w)
            if candidate and not phone:
                phone = candidate
            else:
                rest.append(w)
        if rest:
            name_parts.append(' '.join(rest))
    if not phone:
        return None
    return (' '.join(name_parts).strip(), phone)


def parse_members_text(text):
    """Parse a pasted block (one member per line) into [{name, phone}]."""
    members, seen = [], set()
    for line in (text or '').splitlines():
        parsed = parse_member_line(line)
        if not parsed:
            continue
        name, phone = parsed
        if phone in seen:
            continue
        seen.add(phone)
        members.append({'name': name, 'phone': phone})
    return members
