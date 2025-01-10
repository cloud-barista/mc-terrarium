#!/usr/bin/env python3
import json
import sys

import chardet


def detect_and_convert():
    try:
        # Detect file encoding using a buffered sample
        # 256KiB buffer size is used to reduce memory usage
        with open("ipv4.csv", "rb", buffering=256 * 1024) as file:
            raw_data = file.read()
            result = chardet.detect(raw_data)
            encoding = result["encoding"]

        # If not UTF-8, convert and save back to original file
        if encoding.lower() != "utf-8":
            # Read with detected encoding
            with open("ipv4.csv", "r", encoding=encoding) as f:
                content = f.read()

            # Write back to original file with UTF-8
            with open("ipv4.csv", "w", encoding="utf-8") as f:
                f.write(content)

        print(
            json.dumps(
                {
                    "file": "ipv4.csv",
                    "original_encoding": encoding,
                    "converted": str(encoding.lower() != "utf-8"),
                    "status": "success",
                }
            )
        )
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    detect_and_convert()
