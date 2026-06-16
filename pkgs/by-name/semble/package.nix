{
  lib,
  python3Packages,
  fetchFromGitHub,
  makeWrapper,
  model2vec,
  vicinity,
  bm25s,
}:
python3Packages.buildPythonApplication rec {
  pname = "semble";
  version = "0.3.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "MinishLab";
    repo = "semble";
    rev = "v${version}";
    hash = "sha256-FhpN6Xc0F24oI4DBwiMvcfUNVjXieMdMxuXXmqLuhoY=";
  };

  build-system = with python3Packages; [
    setuptools
    setuptools-scm
  ];

  env.SETUPTOOLS_SCM_PRETEND_VERSION = version;

  dependencies =
    [
      model2vec
      vicinity
      bm25s
    ]
    ++ (with python3Packages; [
      mcp
      numpy
      orjson
      pathspec
      tree-sitter
      tree-sitter-language-pack
      watchfiles
    ]);

  nativeBuildInputs = [
    makeWrapper
  ];

  postInstall = ''
    makeWrapper $out/bin/semble $out/bin/semble-mcp
  '';

  doCheck = false;
  pythonImportsCheck = [
    "semble"
    "semble.cli"
    "semble.mcp"
  ];

  passthru = {
    inherit model2vec vicinity bm25s;
  };

  meta = {
    description = "Fast and accurate local code search for AI agents";
    homepage = "https://github.com/MinishLab/semble";
    changelog = "https://github.com/MinishLab/semble/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = [];
    mainProgram = "semble";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
    ];
  };
}
