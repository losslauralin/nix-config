{
  lib,
  python3Packages,
  fetchPypi,
}:
python3Packages.buildPythonPackage rec {
  pname = "vicinity";
  version = "0.4.4";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-Tg/+G7B4zkYE2nYn0vMgw52W0lKUhdDqpeLEyyuzKys=";
  };

  build-system = with python3Packages; [
    setuptools
    setuptools-scm
  ];

  env.SETUPTOOLS_SCM_PRETEND_VERSION = version;

  dependencies = with python3Packages; [
    numpy
    orjson
    tqdm
  ];

  doCheck = false;
  pythonImportsCheck = ["vicinity"];

  meta = {
    description = "Lightweight nearest neighbors with flexible backends";
    homepage = "https://github.com/MinishLab/vicinity";
    license = lib.licenses.mit;
    maintainers = [];
  };
}
