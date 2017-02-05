{ stdenv, fetchurl, makeWrapper, jre, zookeeper }:

stdenv.mkDerivation rec {
  pname = "exhibitor";
  version = "1.5.6";
  name = "${pname}-${version}";

  src = fetchurl {
    url = "http://search.maven.org/remotecontent?filepath=com/netflix/${pname}/${pname}-standalone/${version}/${pname}-standalone-${version}.jar";
    sha256 = "043yn3ql2nrnl6jmmc718pgg55c9r1grplzc43zdd01pk2rsnh0d";
  };

  buildInputs = [ makeWrapper ];

  propagatedBuildInputs = [ zookeeper ];

  unpackPhase = ":";

  installPhase = ''
     mkdir -pv $out/bin
     cp $src $out/${pname}.jar
     makeWrapper ${jre}/bin/java $out/bin/${pname} --add-flags "-jar $out/${pname}.jar"
  '';

  meta = with stdenv.lib; {
    description = "A Supervisor System for Apache ZooKeeper";
    homepage = https://github.com/soabase/exhibitor/;
    license = licenses.asl20;
    platforms = jre.meta.platforms;
    maintainers = with maintainers; [ pradeepchhetri ];
  };
}
