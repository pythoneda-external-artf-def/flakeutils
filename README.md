# pythoneda-external-artf/flakeutils

Artifact for flake-utils

## How to declare it in your flake

Check the latest tag of this repository: https://github.com/pythoneda-external-artf-def/flakeutils, and use it instead of the `[version]` placeholder below.

```nix
{
  description = "[..]";
  inputs = rec {
    [..]
    pythoneda-external-artf-flakeutils = {
      [optional follows]
      url =
        "github:pythoneda-external-artf-def/flakeutils/[version]";
    };
  };
  outputs = [..]
};
```

Should you use another PythonEDA modules, you might want to pin those also used by this project. The same applies to [https://nixos/nixpkgs](nixpkgs "nixpkgs") and [https://github.com/numtide/flake-utils](flake-utils "flake-utils").

The Nix flake is managed by the [https://github.com/pythoneda-external-artf-def/flakeutils](flakeutils "flakeutils") definition repository.

Use the specific package depending on your system (one of `flake-utils.lib.defaultSystems`) and Python version:

- `#packages.[system].pythoneda-external-artf-flakeutils-python38`
- `#packages.[system].pythoneda-external-artf-flakeutils-python39`
- `#packages.[system].pythoneda-external-artf-flakeutils-python310`
- `#packages.[system].pythoneda-external-artf-flakeutils-python311`
