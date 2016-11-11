{ stdenv, fetchurl, makeFontsConf, makeWrapper
, cairo, coreutils, fontconfig, freefont_ttf
, glib, gmp, gtk2, libffi, libjpeg, libpng
, libtool, mpfr, openssl, pango, poppler
, readline, sqlite
, disableDocs ? true
, version ? "6.7"
, extraLibs ? []
}:

let

  fontsConf = makeFontsConf {
    fontDirectories = [ freefont_ttf ];
  };

  libPath = stdenv.lib.makeLibraryPath ([
    cairo
    fontconfig
    glib
    gmp
    gtk2
    libjpeg
    libpng
    mpfr
    openssl
    pango
    poppler
    readline
    sqlite
  ] ++ extraLibs);

  sha256s = {
    "6.5" = "0gvh7i5k87mg1gpqk8gaq50ja9ksbhnvdqn7qqh0n17byidd6999";
    "6.6" = "1kzdi1n6h6hmz8zd9k8r5a5yp2ryi4w3c2fjm1k6cqicn18cwaxz";
    "6.7" = "0v1nz07vzz0c7rwyz15kbagpl4l42n871vbwij4wrbk2lx22ksgy"; };
  
in

stdenv.mkDerivation rec {
  name = "racket-${version}";
  inherit version;

  src = fetchurl {
    url = "http://mirror.racket-lang.org/installers/${version}/${name}-src.tgz";
    sha256 = sha256s."${version}";
  };

  FONTCONFIG_FILE = fontsConf;
  LD_LIBRARY_PATH = libPath;
  NIX_LDFLAGS = stdenv.lib.optionalString stdenv.cc.isGNU "-lgcc_s";

  buildInputs = [ fontconfig libffi libtool makeWrapper sqlite ];

  preConfigure = ''
    substituteInPlace src/configure --replace /usr/bin/uname ${coreutils}/bin/uname
    mkdir src/build
    cd src/build
  '';

  shared = if stdenv.isDarwin then "dylib" else "shared";
  configureFlags = [ "--enable-${shared}" "--enable-lt=${libtool}/bin/libtool" ]
                   ++ stdenv.lib.optional disableDocs [ "--disable-docs" ]
                   ++ stdenv.lib.optional stdenv.isDarwin [ "--enable-xonx" ];

  configureScript = "../configure";

  enableParallelBuilding = false;

  postInstall = ''
    for p in $(ls $out/bin/) ; do
      wrapProgram $out/bin/$p --set LD_LIBRARY_PATH "${LD_LIBRARY_PATH}";
    done
  '';

  meta = with stdenv.lib; {
    description = "A programmable programming language";
    longDescription = ''
      Racket is a full-spectrum programming language. It goes beyond
      Lisp and Scheme with dialects that support objects, types,
      laziness, and more. Racket enables programmers to link
      components written in different dialects, and it empowers
      programmers to create new, project-specific dialects. Racket's
      libraries support applications from web servers and databases to
      GUIs and charts.
    '';
    homepage = http://racket-lang.org/;
    license = licenses.lgpl3;
    maintainers = with maintainers; [ kkallio henrytill vrthra ];
    platforms = platforms.unix;
  };
}
