#======================================================== =#
# This Nix flake is for use with NixOS or nix package      #
# manager. Nix package manager is available on Linux,      #
# MacOS, or (if you are into this kind of stuff) Windows.  #
#                                                          #
# PURPOSE:                                                 #
# With nix, you don't have to worry about dependencies,    #
# libraries, activation scripts, etc. If it works on one   #
# machine, it works on all of them (as long as they have   #
# nix packages)                                            #
#                                                          #
# USAGE:                                                   #
# To enter the PeakPatch environment, defined in this      #
# flake, after you git cloned this repository and enabled  #
# flakes (as of April 2024, they are experimental), just   #
# run:                                                     #
# `nix develop`                                            #
# All the packages will be downloaded and you will         #
# automatically enter the PeakPatch Nix environment. You   #
# do not have to do anything else.                         #
#                                                          #
# TROUBLESHOOTING:                                         #
# If the command fail, that is probably because you didn't #
# enable flakes. In that case, run the command with        # 
# temporarily enabling them:                               #
#`nix develop --experimental-features 'nix-command flakes'`#
#                                                          #
# CREDITS:                                                 #
# This flake was packaged by Vasilii Pustovoit in April    #
# 2024                                                     #
#======================================================== =#

{
  description = "PeakPatch developement environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
        customFftw_single = pkgs.fftw.override {
          precision = "single";
          enableMpi = true;    
          mpi = pkgs.openmpi;  
        };
		
        customFftw_double = pkgs.fftw.override {
          precision = "double"; 
          enableMpi = true;     
          mpi = pkgs.openmpi;   
        };
        fortran_compiler = pkgs.gfortran13;

        camb = pkgs.python311Packages.buildPythonPackage rec {
          pname = "camb";
          version = "1.5.7";
          #format = "wheel";
          src = pkgs.fetchFromGitHub {
            owner = "cmbant";
            repo = "CAMB";
            rev = "ecd375bff3cd736b3590a22c8f9663b9e6180ee2";
            hash = "sha256-rHUY2S+MDXk/qujlCmC2CS3i6i9SOBtf3sBukEDFdBI=";
            fetchSubmodules = true;
          };

          buildInputs = [ pkgs.which pkgs.gfortran ];
          propagatedBuildInputs = [ pkgs.gfortran ];
          nativeBuildInputs = [ packaging pkgs.gfortran pkgs.which pkgs.python311Packages.setuptools pkgs.python311Packages.wheel ];
          format = "other";
          buildPhase = ''
            python setup.py build
          '';
          # Custom install phase to copy the built files manually
          installPhase = ''
            mkdir -p $out/lib/python3.11/site-packages
            cp -r build/lib*/* $out/lib/python3.11/site-packages/
          '';
          preDistPhases = [ "buildPhase" "installPhase" ];
          postInstall = ''
          '';
        };

        packaging = pkgs.python311Packages.buildPythonPackage rec {
          pname = "packaging";
          version = "24.1";
          format = "pyproject";
          src = pkgs.fetchFromGitHub {
            owner = "pypa";
            repo = "packaging";
            rev = "a716c52b5f3ca9b4a512f538b80ced8ee01b2775";
            hash = "sha256-5ay2MwEw90yc0K3PvyEaxsChX83aJ60jL1rY6q55B2Y=";
          };

          buildInputs = with pkgs.python311Packages; [ pyproject-api flit-core ];
          postInstall = ''
          '';
        };

          # Healpy (failed nix port)
          healpy = pkgs.python311Packages.buildPythonPackage rec {
            pname = "healpy";
            version = "1.16.6";

            src = pkgs.python311Packages.fetchPypi{
              inherit pname;
              inherit version;
              sha256 = "sha256-CrJugo/NJRoUEJWvbZvz26Q87G8PXNSLZb8K+PVjKfE=";
            };

          buildInputs = [ 
            pkgs.python311Packages.numpy 
            pkgs.python311Packages.matplotlib 
            pkgs.python311Packages.astropy 
            pkgs.python311Packages.numpydoc 
            pkgs.python311Packages.cython 
            pkgs.pkg-config
            pkgs.cfitsio
            pkgs.which
            pkgs.zlib
            pkgs.coreutils
            pkgs.bash
          ];

          nativeBuildInputs = [ pkgs.pkg-config ];

          propagatedBuildInputs = [ 
            pkgs.python311Packages.numpy 
            pkgs.python311Packages.matplotlib 
            pkgs.python311Packages.astropy 
            pkgs.python311Packages.numpydoc 
            pkgs.python311Packages.cython 
            pkgs.pkg-config
            pkgs.cfitsio
            pkgs.which
            pkgs.zlib
          ];
          
          preBuild = ''
            export PKG_CONFIG="${pkgs.pkg-config}/bin/pkg-config"
            export PATH=${pkgs.coreutils}/bin:$PATH
            export PKG_CONFIG_PATH="${pkgs.zlib}/lib/pkgconfig"

            # Add the existing PKG_CONFIG_PATH if it's set
            if [ -n "$PKG_CONFIG_PATH" ]; then
              export PKG_CONFIG_PATH="${pkgs.zlib}/lib:$PKG_CONFIG_PATH"
            else
              export PKG_CONFIG_PATH="${pkgs.zlib}/lib"
            fi
            echo "Environment Variables:"
            env
          '';

          postPatch = ''
            substituteInPlace setup.py \
              --replace "find_packages()" "find_packages(include=['healpy', 'healpy.*'])"
          '';
          };
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            (python3.withPackages (ps: with ps; [
              #healpy # HEALPY IS NOT IN NIXPKGS, SO NEED TO MANUALLY PACKAGE IT!
              pandas
              matplotlib
              numpy
              astropy
              scipy
			  camb
			  numba
            ]))
            which
            gsl
            #cfitsio
            gcc
            mpi
			fortran_compiler
            llvmPackages.openmp
            customFftw_single
            customFftw_double
			hdf5
			perl

			# Non-Gaussianities
			#blas
			#lapack

			# Running Jupyter notebooks
			#jupyter

			# Debuggers - can remove this if you want
			gdb
			valgrind
			# These are needed for tmpi
			reptyr
			mpich

			# These are needed for MUSIC
			gfortran.cc
          ];
          shellHook = ''
            # Set the paths to FFTW, GFORT, MPI libraries used by GIZMO
            export FFTW_SINGLE_PATH=${customFftw_single.dev}
            export FFTW_DOUBLE_PATH=${customFftw_double.dev}
            export MPI_PATH=${pkgs.mpich}
            export PERL_PATH=${pkgs.perl}

			# MUSIC-required inputs
            export FFTW_PATH=${customFftw_single}
            export HDF5_PATH=${pkgs.hdf5}
		    export GFORTCC_PATH=${pkgs.gfortran.cc}
		    export GFORT_LPATH=${fortran_compiler.cc.lib}/lib
		    export GCC_PATH=${pkgs.gcc}

            export GSL_INCLUDE_PATH=${pkgs.gsl.dev}/include
            export GSL_LIBRARY_PATH=${pkgs.gsl}/lib
            export HDF5_INCLUDE_PATH=${pkgs.hdf5.dev}/include
            export HDF5_LIBRARY_PATH=${pkgs.hdf5}/lib
			export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [ 
															 	pkgs.mpich
															 	pkgs.gcc.cc.lib
																pkgs.blas
                                                                #pkgs.lapack
															 	#fortran_compiler.cc.lib
														       ]
								     }:$LD_LIBRARY_PATH


            # This flag will let peakpatchtools.py know that we're running on nix.
            # As of April 2024, healpy isn't packaged in nixpkgs, and I wasted a whole day trying 
            # to package it myself (see above). You are welcome to continue packaging it, or
            # allow peakpatchtools.py to use healpy once it's packaged in nixpkgs
			# This flag is also required to run MUSIC
            export NIX_BUILD=1
            export SYSTYPE='nix'

            # Create useful aliases and utility environment variables
            export GIZMO_ALIASES='
'
		    alias pphelp="echo \"$GIZMO_ALIASES\""
            # Welcome message
			echo "
#########################################################
##################  Welcome to GIZMO! ###################
#########################################################
		    "
			echo "$GIZMO_ALIASES"
          '';
      };
    }
  );
}

