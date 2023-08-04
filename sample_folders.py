#!/usr/bin/env python
import random
from collections import defaultdict
from copy import deepcopy
from pathlib import Path

import click
import numpy as np

DATA_PATH = Path(Path(__file__).parents[1] / 'data/')


@click.command()
@click.option(
    '--lambda_val',
    '-l',
    type=int,
    default=11,
    required=True,
    help='lambda value for Poisson sampling distribution',
)
@click.option(
    '--num_samples',
    '-n',
    type=int,
    required=True,
    help='Number of total documents to sample when building bundles',
)
@click.argument('docs')
def cli(docs, num_samples, lambda_val):
    paths = []
    bundles = defaultdict(list)
    for path in DATA_PATH.glob('*'):
        paths.append(str(path).split('/')[-1])

    rng = np.random.default_rng()
    expend_paths = deepcopy(paths)

    while expend_paths:
        random.shuffle(expend_paths)
        bundles[random.randint(1, num_samples)].append(expend_paths.pop())

    for i, n in enumerate(rng.poisson(lambda_val, num_samples)):
        for name in rng.choice(paths, n):
            bundles[i + 1].append(name)

    counter = 1
    for v in bundles.values():
        for stem in v:
            print(stem, counter)
        counter += 1


if __name__ == '__main__':
    cli()
