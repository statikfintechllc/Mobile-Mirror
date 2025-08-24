import logging
import sys
import sys

logger = logging.getLogger(__name__)

if not logger.hasHandlers():
    logger.setLevel(logging.INFO)
    _sc = logging.StreamHandler(stream=sys.stdout)
    # JobLogger already has [%(asctime)s] [%(levelname)s]
    _formatter = logging.Formatter("[%(filename)s:%(lineno)d:%(funcName)s] %(message)s")
    _sc.setFormatter(_formatter)
    logger.addHandler(_sc)
    logger.propagate = False