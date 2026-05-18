from importlib.metadata import version, PackageNotFoundError

try:
    __version__ = version("high_dim_gp")
except PackageNotFoundError:
    __version__ = "0.1.0"  # fallback for PYTHONPATH usage
