{
  lib,
  python3Packages,
  fetchPypi,
}:
python3Packages.buildPythonPackage rec {
  pname = "bm25s";
  version = "0.3.9";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-iVxnnZUrfeg1XttfPhpiCh4vKU0dQrkZvwghzOLi9Zc=";
  };

  build-system = with python3Packages; [
    setuptools
  ];

  dependencies = with python3Packages; [
    numba
    numpy
    orjson
    pystemmer
    tqdm
  ];

  doCheck = false;
  pythonImportsCheck = ["bm25s"];

  meta = {
    description = "Fast BM25 implementation for text ranking";
    homepage = "https://github.com/xhluca/bm25s";
    license = lib.licenses.mit;
    maintainers = [];
  };
}
