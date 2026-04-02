# nix/python.nix — uv2nix virtual environment builder
{
  python311,
  lib,
  stdenv,
  callPackage,
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
}:
let
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./..; };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  pythonSet =
    (callPackage pyproject-nix.build.packages {
      python = python311;
    }).overrideScope
      (lib.composeManyExtensions [
        pyproject-build-systems.overlays.default
        overlay
      ]);

  # The "voice" extra pulls in faster-whisper → onnxruntime, which only ships
  # wheel-only builds for macosx_14_0_arm64. uv2nix cannot match this tag on
  # aarch64-darwin, so we exclude "voice" on Darwin and install all other extras.
  extras =
    if stdenv.hostPlatform.isDarwin then [
      "messaging" "cron" "cli" "slack" "pty" "mcp"
    ] else [ "all" ];
in
pythonSet.mkVirtualEnv "hermes-agent-env" {
  hermes-agent = extras;
}
