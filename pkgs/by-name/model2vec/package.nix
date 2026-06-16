{
  lib,
  python3Packages,
  fetchPypi,
}:
python3Packages.buildPythonPackage rec {
  pname = "model2vec";
  version = "0.8.1";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-mjXTX2pETkzsGfICfuEGxUllzSa3/UpPACtfPitnd/Q=";
  };

  build-system = with python3Packages; [
    setuptools
    setuptools-scm
  ];

  env.SETUPTOOLS_SCM_PRETEND_VERSION = version;

  dependencies = with python3Packages; [
    jinja2
    joblib
    numpy
    rich
    safetensors
    tokenizers
    tqdm
  ];

  doCheck = false;
  pythonImportsCheck = ["model2vec"];

  meta = {
    description = "Fast state-of-the-art static embeddings";
    homepage = "https://github.com/MinishLab/model2vec";
    license = lib.licenses.mit;
    maintainers = [];
  };
}
