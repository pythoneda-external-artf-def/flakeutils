# flakeutils/flake.nix
#
# This file defines a nix flake for flakeutils-0.0.0.
#
# GNU GENERAL PUBLIC LICENSE
# Version 3, 29 June 2007
#
# Copyright (C) 2024-today rydnr https://github.com/pythoneda-external-artf/flakeutils
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
{
  description = "Artifact for flake-utils";
  inputs = rec {
    flake-utils = {
      url = "github:numtide/flake-utils/v1.0.0";
    };
    nixos = {
      url = "github:NixOS/nixpkgs/23.11";
    };
    pythoneda-shared-banner = {
      url = "github:pythoneda-shared-pythonlang-def/banner/0.0.49";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
    };
    pythoneda-shared-domain = {
      url = "github:pythoneda-shared-def/domain/0.0.36";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixos.follows = "nixos";
      inputs.pythoneda-shared-banner.follows = "pythoneda-shared-banner";
    };
  };
  outputs = inputs:
    with inputs;
    let
      defaultSystems = flake-utils.lib.defaultSystems;
      supportedSystems = if builtins.elem "armv6l-linux" defaultSystems then
        defaultSystems
      else
        defaultSystems ++ [ "armv6l-linux" ];
    in flake-utils.lib.eachSystem supportedSystems (system:
      let
        org = "pythoneda-external-artf";
        repo = "flakeutils";
        version = "0.0.0";
        sha256 = "14w99y43ks5jc7q73461m92v0mzkpciq0fjz5r5qi3r3mgwa4ikp";
        pname = "${org}-${repo}";
        pythonpackage = "pythoneda.artifact.external.flakeutils";
        package = builtins.replaceStrings [ "." ] [ "/" ] pythonpackage;
        entrypoint = "flakeutils_app";
        description = "Artifact for flake-utils";
        license = pkgs.lib.licenses.gpl3;
        homepage = "https://github.com/${org}/${repo}";
        maintainers = [ "rydnr <github@acm-sl.org>"  ];
        archRole = "B";
        space = "D";
        layer = "D";
        nixosVersion = builtins.readFile "${nixos}/.version";
        nixpkgsRelease =
          builtins.replaceStrings [ "\n" ] [ "" ] "nixos-${nixosVersion}";
        shared = import "${pythoneda-shared-banner}/nix/shared.nix";
        pkgs = import nixos { inherit system; };
        flakeutils-for = { python , pythoneda-shared-banner , pythoneda-shared-domain  }:
          let
            pnameWithUnderscores =
              builtins.replaceStrings [ "-" ] [ "_" ] pname;
            pythonVersionParts = builtins.splitVersion python.version;
            pythonMajorVersion = builtins.head pythonVersionParts;
            pythonMajorMinorVersion =
              "${pythonMajorVersion}.${builtins.elemAt pythonVersionParts 1}";
            wheelName =
              "${pnameWithUnderscores}-${version}-py${pythonMajorVersion}-none-any.whl";
            banner_file = "${package}/flakeutils_banner.py";
            banner_class = "flakeutilsBanner";
          in python.pkgs.buildPythonPackage rec {
            inherit pname version;
            projectDir = ./.;
            pyprojectTemplateFile = ./pyprojecttoml.template;
            pyprojectTemplate = pkgs.substituteAll {
              authors = builtins.concatStringsSep ","
                (map (item: ''"${item}"'') maintainers);
              desc = description;
              inherit homepage pname pythonMajorMinorVersion pythonpackage
                version;
              pythonedaSharedBanner = pythoneda-shared-banner.version;
              pythonedaSharedDomain = pythoneda-shared-domain.version;

              package = builtins.replaceStrings [ "." ] [ "/" ] pythonpackage;
              src = pyprojectTemplateFile;
            };
            bannerTemplateFile =
              "${pythoneda-shared-banner}/templates/banner.py.template";
            bannerTemplate = pkgs.substituteAll {
              project_name = pname;
              file_path = banner_file;
              inherit banner_class org repo;
              tag = version;
              pescio_space = space;
              arch_role = archRole;
              hexagonal_layer = layer;
              python_version = pythonMajorMinorVersion;
              nixpkgs_release = nixpkgsRelease;
              src = bannerTemplateFile;
            };

            entrypointTemplateFile =
              "${pythoneda-shared-banner}/templates/entrypoint.sh.template";
            entrypointTemplate = pkgs.substituteAll {
              arch_role = archRole;
              hexagonal_layer = layer;
              nixpkgs_release = nixpkgsRelease;
              inherit homepage maintainers org python repo version;
              pescio_space = space;
              python_version = pythonMajorMinorVersion;
              pythoneda_shared_banner = pythoneda-shared-banner;
              pythoneda_shared_domain = pythoneda-shared-domain;
              src = entrypointTemplateFile;
            };
            src = pkgs.fetchFromGitHub {
              owner = org;
              rev = version;
              inherit repo sha256;
            };

            format = "pyproject";

            nativeBuildInputs = with python.pkgs; [ pip poetry-core ];
            propagatedBuildInputs = with python.pkgs; [
              pythoneda-shared-banner
              pythoneda-shared-domain

            ];

            # pythonImportsCheck = [ pythonpackage ];

            unpackPhase = ''
              cp -r ${src} .
              sourceRoot=$(ls | grep -v env-vars)
              find $sourceRoot -type d -exec chmod 777 {} \;
              cp ${pyprojectTemplate} $sourceRoot/pyproject.toml
              cp ${bannerTemplate} $sourceRoot/${banner_file}
              cp ${entrypointTemplate} $sourceRoot/entrypoint.sh
            '';

            postPatch = ''
              substituteInPlace /build/$sourceRoot/entrypoint.sh \
                --replace "@SOURCE@" "$out/bin/${entrypoint}.sh" \
                --replace "@PYTHONPATH@" "$PYTHONPATH:$out/lib/python${pythonMajorMinorVersion}/site-packages" \
                --replace "@CUSTOM_CONTENT@" "" \
                --replace "@ENTRYPOINT@" "$out/lib/python${pythonMajorMinorVersion}/site-packages/${package}/application/${entrypoint}.py" \
                --replace "@BANNER@" "$out/bin/banner.sh"
            '';

            postInstall = ''
              pushd /build/$sourceRoot
              for f in $(find . -name '__init__.py'); do
                if [[ ! -e $out/lib/python${pythonMajorMinorVersion}/site-packages/$f ]]; then
                  cp $f $out/lib/python${pythonMajorMinorVersion}/site-packages/$f;
                fi
              done
              popd
              mkdir $out/dist $out/bin
              cp dist/${wheelName} $out/dist
              cp /build/$sourceRoot/entrypoint.sh $out/bin/${entrypoint}.sh
              chmod +x $out/bin/${entrypoint}.sh
              echo '#!/usr/bin/env sh' > $out/bin/banner.sh
              echo "export PYTHONPATH=$PYTHONPATH" >> $out/bin/banner.sh
              echo "${python}/bin/python $out/lib/python${pythonMajorMinorVersion}/site-packages/${banner_file} \$@" >> $out/bin/banner.sh
              chmod +x $out/bin/banner.sh
            '';

            meta = with pkgs.lib; {
              inherit description homepage license maintainers;
            };
          };
      in rec {
        apps = rec {
          default = flakeutils-default;
          flakeutils-default = flakeutils-python311;
          flakeutils-python38 = shared.app-for {
            package = self.packages.${system}.flakeutils-python38;
            inherit entrypoint;
          };
          flakeutils-python39 = shared.app-for {
            package = self.packages.${system}.flakeutils-python39;
            inherit entrypoint;
          };
          flakeutils-python310 = shared.app-for {
            package = self.packages.${system}.flakeutils-python310;
            inherit entrypoint;
          };
          flakeutils-python311 = shared.app-for {
            package = self.packages.${system}.flakeutils-python311;
            inherit entrypoint;
          };
        };
        defaultApp = apps.default;
        defaultPackage = packages.default;
        devShells = rec {
          default = flakeutils-default;
          flakeutils-default = flakeutils-python311;
          flakeutils-python38 = shared.devShell-for {
            banner = "${
                pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python38
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.flakeutils-python38;
            python = pkgs.python38;
            pythoneda-shared-banner =
              pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python38;
            pythoneda-shared-domain =
              pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python38;
            inherit archRole layer org pkgs repo space;
          };
          flakeutils-python39 = shared.devShell-for {
            banner = "${
                pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python39
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.flakeutils-python39;
            python = pkgs.python39;
            pythoneda-shared-banner =
              pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python39;
            pythoneda-shared-domain =
              pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python39;
            inherit archRole layer org pkgs repo space;
          };
          flakeutils-python310 = shared.devShell-for {
            banner = "${
                pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python310
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.flakeutils-python310;
            python = pkgs.python310;
            pythoneda-shared-banner =
              pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python310;
            pythoneda-shared-domain =
              pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python310;
            inherit archRole layer org pkgs repo space;
          };
          flakeutils-python311 = shared.devShell-for {
            banner = "${
                pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python311
              }/bin/banner.sh";
            extra-namespaces = "";
            nixpkgs-release = nixpkgsRelease;
            package = packages.flakeutils-python311;
            python = pkgs.python311;
            pythoneda-shared-banner =
              pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python311;
            pythoneda-shared-domain =
              pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python311;
            inherit archRole layer org pkgs repo space;
          };
        };
        packages = rec {
          default = flakeutils-default;
          flakeutils-default = flakeutils-python311;
          flakeutils-python38 = flakeutils-for {
            python = pkgs.python38;
            pythoneda-shared-banner = pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python38;
            pythoneda-shared-domain = pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python38;
          };
          flakeutils-python39 = flakeutils-for {
            python = pkgs.python39;
            pythoneda-shared-banner = pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python39;
            pythoneda-shared-domain = pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python39;
          };
          flakeutils-python310 = flakeutils-for {
            python = pkgs.python310;
            pythoneda-shared-banner = pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python310;
            pythoneda-shared-domain = pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python310;
          };
          flakeutils-python311 = flakeutils-for {
            python = pkgs.python311;
            pythoneda-shared-banner = pythoneda-shared-banner.packages.${system}.pythoneda-shared-banner-python311;
            pythoneda-shared-domain = pythoneda-shared-domain.packages.${system}.pythoneda-shared-domain-python311;
          };
        };
      });
}