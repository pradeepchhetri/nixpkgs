{ stdenv, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "acme-${version}";
  version = "0.0.59";
  rev = "v${version}";

  goPackagePath = "https://github.com/hlandau/acme";

  src = fetchFromGitHub {
    owner = "hlandau";
    repo = "acme";
    inherit rev;
    sha256 = "1fcr5jr0vn5w60bn08lkh2mi0hdarwp361h94in03139j7hhqrfs";
  };

  meta = with stdenv.lib; {
    homepage = https://hlandau.github.io/acme/;
    description = "An automatic certificate acquisition tool for ACME";
    license = licenses.mit;
    maintainers = with maintainers; [ pradeepchhetri ];
  };
}
