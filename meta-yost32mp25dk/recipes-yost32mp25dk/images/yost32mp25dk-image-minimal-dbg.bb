SUMMARY = "OpenSTLinux debug image derived from minimal"

require yost32mp25dk-image-minimal.bb

# Add debug tooling while inheriting all minimal image content.
IMAGE_FEATURES += "dbg-pkgs"
