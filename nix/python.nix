# nix/python.nix — uv2nix virtual environment builder
{
  python311,
  lib,
  callPackage,
  stdenv,
  fetchurl,
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
}:
let
  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./..; };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  # uv2nix fails to match the macosx_14_0_arm64 wheel for onnxruntime on
  # aarch64-darwin. Provide the wheel directly so platform detection is bypassed.
  onnxruntimeOverlay = final: prev:
    lib.optionalAttrs stdenv.hostPlatform.isDarwin {
      onnxruntime = prev.onnxruntime.overrideAttrs (_: {
        src = fetchurl {
          url = "https://files.pythonhosted.org/packages/60/69/6c40720201012c6af9aa7d4ecdd620e521bd806dc6269d636fdd5c5aeebe/onnxruntime-1.24.4-cp311-cp311-macosx_14_0_arm64.whl";
          hash = "sha256:0bdfce8e9a6497cec584aab407b71bf697dac5e1b7b7974adc50bf7533bdb3a2";
        };
      });
    };

  pythonSet =
    (callPackage pyproject-nix.build.packages {
      python = python311;
    }).overrideScope
      (lib.composeManyExtensions [
        pyproject-build-systems.overlays.default
        overlay
        onnxruntimeOverlay
      ]);
in
pythonSet.mkVirtualEnv "hermes-agent-env" {
  hermes-agent = [ "all" ];
}
