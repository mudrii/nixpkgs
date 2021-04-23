{ mkDerivation
, cmake
, fetchFromGitLab
, nix-update-script
, gst_all_1
, lib
, libpulseaudio
, ninja
, pcre
, pkg-config
, qtbase
, qttools
, taglib
, zlib
, python3
}:

let
  py = python3.withPackages (ps: with ps; [
    pydbus
  ]);
in
mkDerivation rec {
  pname = "sayonara";
  version = "1.6.0-beta7";

  src = fetchFromGitLab {
    owner = "luciocarreras";
    repo = "sayonara-player";
    rev = version;
    sha256 = "14svszfldx32vn937rszd21rgl31vb5kzs0hnrg41ygx0br61rvd";
  };

  nativeBuildInputs = [ cmake ninja pkg-config qttools ];

  buildInputs = [
    libpulseaudio
    pcre
    qtbase
    taglib
    zlib
    py
  ]
  ++ (with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
  ]);

  # we carry the patched taglib 1.11.1 that doesn't break ogg but sayonara just
  # checks for the version
  cmakeFlags = [
    "-DWITH_SYSTEM_TAGLIB=ON"
  ];

  # gstreamer cannot otherwise be found
  env.NIX_CFLAGS_COMPILE = "-I${gst_all_1.gst-plugins-base.dev}/include/gstreamer-1.0";

  postInstall = ''
    qtWrapperArgs+=(--prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0")
  '';

  passthru = {
    updateScript = nix-update-script {
      attrPath = pname;
    };
  };

  meta = with lib; {
    description = "Sayonara music player";
    homepage = "https://sayonara-player.com/";
    license = licenses.gpl3;
    maintainers = with maintainers; [ deepfire ];
    platforms = platforms.unix;
  };
}
