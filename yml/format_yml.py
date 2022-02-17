#!/usr/bin/env python3

import sys
import yaml

with open(sys.argv[1]) as fh_in:
    contents = yaml.safe_load(fh_in)

with open(sys.argv[1], "w") as fh_out:
    fh_out.write(yaml.dump(contents))
