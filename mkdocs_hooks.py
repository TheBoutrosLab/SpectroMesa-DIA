"""Build Home from README and use pipeline flowcharts from their original sources."""

from pathlib import Path

from mkdocs.exceptions import PluginError
from mkdocs.structure.files import File


PIPELINE_DIAGRAMS = {
    "conversion": "convert-MSData/img/flow-diagram.drawio.svg",
    "search": "search-ProteomicDIA/img/flow-diagram.svg",
    "validation": "validate-ProteomicPSM/img/flow-diagram.drawio.svg",
    "library": "generate-ProteomicSpectralLibrary/docs/pipeline-flow.svg",
    "quantitation": "quantitate-ProteomicDIA/img/flow-diagram.svg",
    "qc": "qc-ProteomicDIA/img/flow-diagram.svg",
}


def _source(config, relative_path):
    root = Path(config.config_file_path).resolve().parent
    source = root / "external" / relative_path
    if not source.is_file():
        raise PluginError(
            f"Missing pipeline flowchart source: {source}. "
            "Initialize the pipeline submodules before building documentation."
        )
    return source


def _root(config):
    return Path(config.config_file_path).resolve().parent


def _external_file(config, destination, source):
    # File.generated requires MkDocs 1.6; the publishing action uses 1.5.3.
    file = File(destination, config.docs_dir, config.site_dir, config.use_directory_urls)
    file.abs_src_path = str(source)
    return file


def on_config(config):
    # The publishing action prepends its own Home entry to our navigation.
    # Keep one Home in the same position in both local and publishing builds.
    config.nav = [{"Home": "index.md"}] + [
        item for item in config.nav
        if not (isinstance(item, dict) and "index.md" in item.values())
    ]
    return config


def on_page_read_source(page, config):
    if page.file.src_uri != "index.md":
        return None
    readme = (_root(config) / "README.md").read_text(encoding="utf-8")
    # README links are relative to the repository; Home lives at the docs root.
    readme = readme.replace("](docs/", "](")
    readme = readme.replace('src="docs/', 'src="')
    repo = config.repo_url.rstrip("/")
    page.edit_url = (
        repo.replace("/tree/", "/blob/", 1) + "/README.md"
        if "/tree/" in repo else repo + "/blob/main/README.md"
    )
    return readme


def on_files(files, config):
    # Use README even when the publishing action has generated docs/index.md.
    existing = files.get_file_from_path("index.md")
    if existing is not None:
        files.remove(existing)
    files.append(_external_file(config, "index.md", _root(config) / "README.md"))
    if files.get_file_from_path("LICENSE") is None:
        files.append(_external_file(config, "LICENSE", _root(config) / "LICENSE"))

    # Only the built site gets chart assets; their sources stay in the pipelines.
    for name, relative_path in PIPELINE_DIAGRAMS.items():
        files.append(_external_file(
            config, f"pipelines/flowcharts/{name}.svg", _source(config, relative_path)
        ))
    return files


def on_serve(server, config, builder):
    server.watch(str(_root(config) / "README.md"), builder)
    server.watch(str(_root(config) / "LICENSE"), builder)
    for relative_path in PIPELINE_DIAGRAMS.values():
        server.watch(str(_source(config, relative_path)), builder)
    return server
