#!/usr/bin/env python3
"""validate_content_pack.py

Optional helper script to validate content packs against the JSON Schemas in assets/schemas.

Usage:
  python scripts/validate_content_pack.py assets/sample_content/content_pack_en.json

Notes:
- Requires: pip install jsonschema
- This script is provided as a convenience; CI integration is optional.
"""

import json
import sys
from pathlib import Path

try:
    import jsonschema
except ImportError:
    print("Missing dependency: jsonschema. Install with: pip install jsonschema")
    sys.exit(2)

ROOT = Path(__file__).resolve().parents[1]
SCHEMAS = ROOT / "assets" / "schemas"

def load_schema(name: str) -> dict:
    return json.loads((SCHEMAS / name).read_text(encoding="utf-8"))

def main():
    if len(sys.argv) != 2:
        print("Usage: python scripts/validate_content_pack.py <content_pack.json>")
        sys.exit(2)

    content_path = Path(sys.argv[1])
    data = json.loads(content_path.read_text(encoding="utf-8"))

    # Load schemas
    pack_schema = load_schema("content-pack.schema.json")
    aff_schema = load_schema("affirmation.schema.json")
    cat_schema = load_schema("category.schema.json")

    # Resolve local refs manually for this small set
    def resolver(uri):
        if uri.endswith("affirmation.schema.json"):
            return aff_schema
        if uri.endswith("category.schema.json"):
            return cat_schema
        raise ValueError(f"Unknown schema ref: {uri}")

    class LocalRefResolver(jsonschema.RefResolver):
        def resolve_remote(self, uri):
            return resolver(uri)

    resolver_obj = LocalRefResolver.from_schema(pack_schema, store={
        "affirmation.schema.json": aff_schema,
        "category.schema.json": cat_schema,
        "content-pack.schema.json": pack_schema
    })

    jsonschema.validate(instance=data, schema=pack_schema, resolver=resolver_obj)
    print("OK: content pack is valid")

if __name__ == "__main__":
    main()
