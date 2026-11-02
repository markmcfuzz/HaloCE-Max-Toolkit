"""Adding, duplicating and deleting block elements in the key -> text fields of a Point.
Element keys look like "unit.seats[2].yaw rate"; the count is "unit.seats" = "3"."""
import re


def default_values(fields, prefix, out):
    """Zero / empty text for every field of a new element (as the exporter reads missing ones)."""
    for field in fields:
        key = prefix + field["key"]
        kind = field["kind"]
        if kind == "block":
            count = field.get("count", 0)  # arrays always have their elements
            out[key] = str(count)
            for i in range(count):
                default_values(field["fields"], "%s[%d]." % (key, i), out)
        elif kind in ("floats", "angles", "ints", "color"):
            out[key] = " ".join(["0"] * field["parts"])
        elif kind == "ref":
            out[key] = ":"
        elif kind == "text":
            out[key] = ""
        else:
            out[key] = "0"
    return out


def _count(values, count_key):
    try:
        return max(0, int(values.get(count_key, "0")))
    except ValueError:
        return 0


def _renumbered(values, count_key, first, delta, drop=None):
    """Copy of values with elements >= first moved by delta; element drop is left out."""
    pattern = re.compile(re.escape(count_key) + r"\[(\d+)\]\.(.*)$", re.S)
    out = {}
    for key, text in values.items():
        match = pattern.match(key)
        if match:
            i = int(match.group(1))
            if i == drop:
                continue
            if i >= first:
                key = "%s[%d].%s" % (count_key, i + delta, match.group(2))
        out[key] = text
    return out


def add(values, field, count_key):
    """New element at the end. Returns (values, its index)."""
    count = _count(values, count_key)
    out = dict(values)
    default_values(field["fields"], "%s[%d]." % (count_key, count), out)
    out[count_key] = str(count + 1)
    return out, count


def duplicate(values, count_key, index):
    """Copy of element index right after it. Returns (values, the copy's index)."""
    count = _count(values, count_key)
    out = _renumbered(values, count_key, index + 1, 1)
    source = "%s[%d]." % (count_key, index)
    target = "%s[%d]." % (count_key, index + 1)
    for key, text in list(out.items()):
        if key.startswith(source):
            out[target + key[len(source):]] = text
    out[count_key] = str(count + 1)
    return out, index + 1


def delete(values, count_key, index):
    """Removes element index. Returns (values, the index to show next, -1 when none left)."""
    count = _count(values, count_key)
    out = _renumbered(values, count_key, index + 1, -1, drop=index)
    out[count_key] = str(count - 1)
    return out, min(index, count - 2)
