{ stdenv, fetchFromGitHub, cairo, coreutils, curl, flex, gfortran, hdf4
, hdf5-fortran, libjpeg, makedepend, makeWrapper, netcdf, netcdffortran, szip
, xorg, yacc, zlib, tcsh }:

let xlibs = with xorg; [ libX11 libXaw libXext libXmu libXt libSM libXpm libICE ];
in stdenv.mkDerivation rec {
  pname = "NCL";
  version = "6.6.2";

  src = fetchFromGitHub {
    owner = "NCAR";
    repo = "ncl";
    rev = version;
    sha256 = "0ybn4f3mvqxq9k1p9bflbhq4i4yppdnssbq4rz3wigj6k17dcw4i";
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [
    cairo
    curl
    flex
    gfortran
    hdf4
    hdf5-fortran
    libjpeg
    makedepend
    netcdf
    netcdffortran
    szip
    tcsh
    yacc
    zlib
  ] ++ xlibs;

  prePatch = ''
    echo "
    #ifdef FirstSite

    #endif /* FirstSite */

    #ifdef SecondSite

    #define YmakeRoot $out
    #define NcargRoot $out

    #define NetCDF4lib  -lnetcdf

    #define LibSearch  -L${hdf4.out}/lib -L${hdf5-fortran}/lib -L${libjpeg}/lib -L${netcdffortran}/lib -L${netcdf}/lib
    #define IncSearch  -I${hdf4.dev}/include -I${hdf5-fortran.dev}/include -I${libjpeg.dev}/include -I${netcdffortran}/include -I${netcdf}/include

    #define BuildRasterHDF 0
    #define HDFlib
    #define BuildHDF4 0
    #define HDFlib
    #define HDFlib -lmfhdf -lhdf -ljpeg
    #define HDF5lib -lhdf5_hl -lhdf5
    #define BuildTRIANGLE 0
    #define BuildUdunits 0
    #define UdUnitslib
    #define BuildHDFEOS 0
    #define HDFEOSlib
    #define BuildHDFEOS5 0
    #define HDFEOS5lib
    #define BuildGRIB2 0
    #define GRIB2lib
    #define BuildEEMD 0
    #define EEMDlib

    #define CCompiler   ${gfortran}/bin/gcc
    #define FCompiler   ${gfortran}/bin/gfortran
    #define CxxCompiler ${gfortran}/bin/g++
    #define CppCommand  '${gfortran}/bin/cpp -traditional'
    #define LdCommand   ${gfortran}/bin/ld

    #define RmCommand   "${coreutils}/bin/rm -f"
    #define CopyCommand ${coreutils}/bin/cp
    #define MoveCommand ${coreutils}/bin/mv

    #endif /* SecondSite */" > config/Site.local

    # Hard-coded abspaths are extremely prevalent in the codebase (I'm probably
    # missing some somewhere)
    substituteInPlace Configure \
      --replace "/bin/csh" "${tcsh}/bin/tcsh"

    substituteInPlace Configure \
      --replace "/bin/rm" "${coreutils}/bin/rm"

    substituteInPlace config/ymake-install \
      --replace "/bin/csh" "${tcsh}/bin/tcsh"

    substituteInPlace config/ymake-install \
      --replace "/bin/chmod" "${coreutils}/bin/chmod"

    substituteInPlace config/ymake-install \
      --replace "/bin/cp" "${coreutils}/bin/cp"

    substituteInPlace config/ymkmf \
      --replace "/bin/csh" "${tcsh}/bin/tcsh"

    substituteInPlace config/ymake \
      --replace "/bin/csh" "${tcsh}/bin/tcsh"

    substituteInPlace config/ymake \
      --replace "/bin/rm" "${coreutils}/bin/rm"

    # Either the printf calls need to be patched to include a format string, or
    # the format hardening needs to be turned off (see the nixpkgs manual,
    # sec. Hardening in Nixpkgs)
    substituteInPlace ni/src/lib/nfp/wrf_vinterpW.c \
      --replace 'fprintf(stderr, errmsg);' 'fprintf(stderr, "%s", errmsg);'

    substituteInPlace ni/src/lib/nfp/wrfW.c \
      --replace 'fprintf(stderr, errmsg);' 'fprintf(stderr, "%s", errmsg);'

    substituteInPlace ni/src/lib/nfp/ripW.c \
      --replace 'fprintf(stderr, errmsg);' 'fprintf(stderr, "%s", errmsg);'
  '';

  patches = [ ./0001-On-no-branch-ymake-cpp.patch ];
  
  configurePhase = ''
    echo "Configuring for $(uname)"
    echo -e "n\n" | ./Configure
  '';

  buildPhase = ''
    make Build
  '';

  postFixup =
    let tcshPath = stdenv.lib.strings.escape [ "/" ] "${tcsh}/bin/tcsh";
    in ''
      for i in $out/bin/*; do
        # Use sed instead of substituteInPlace, otherwise we would have to be
        # careful that we don't accidentally apply the latter to any binaries
        sed -i -e "1s/#!\/bin\/csh/#!${tcshPath}/" $i
        wrapProgram $i \
          --set NCARG_ROOT $out \
          --prefix PATH : $out/bin \
          --prefix MANPATH : $out/man 
      done
    '';

}
