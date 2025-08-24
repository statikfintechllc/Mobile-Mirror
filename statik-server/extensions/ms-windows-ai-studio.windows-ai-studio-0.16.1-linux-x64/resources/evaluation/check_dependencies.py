import importlib
import sys

def try_get_module_version(pkg_name):
    """
    Helper function to retrieve the version number of a specified package.
    Returns None if the package is not installed or does not exist.
    See https://stackoverflow.com/a/32965521 for reference.
    """
    try:
        from importlib.metadata import version

        ver = version(pkg_name)
        if ver is not None:
            return ver
    except Exception:
        pass

    try:
        import pkg_resources

        dist = pkg_resources.get_distribution(pkg_name)
        if dist is not None and dist.version is not None:
            return dist.version
    except Exception:
        pass

    try:
        imported_module = importlib.import_module(pkg_name)
        if (
            imported_module is not None
            and imported_module.__version__ is not None
        ):
            return imported_module.__version__
    except Exception:
        pass

    return None

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python check_dependencies.py <package_name>")
        sys.exit(1)

    package_name = sys.argv[1]
    res = try_get_module_version(package_name)
    print(res)