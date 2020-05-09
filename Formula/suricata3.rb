class Suricata3 < Formula
  desc "Network IDS, IPS, and security monitoring engine (version 3.0)"
  homepage "http://suricata-ids.org"
  url "http://www.openinfosecfoundation.org/download/suricata-3.0.tar.gz"
  sha256 "4b8feb398a0800c955fe24aa31ca446c539e79492155717e826473f902c8e65a"

  depends_on :python if MacOS.version <= :snow_leopard
  depends_on "pkg-config" => :build
  depends_on "libmagic"
  depends_on "libnet"
  depends_on "libyaml"
  depends_on "pcre"
  depends_on "geoip" => :optional
  depends_on "lua" => :optional
  depends_on "luajit" => :optional
  depends_on "jansson" => :optional

  resource "argparse" do
    url "https://pypi.python.org/packages/source/a/argparse/argparse-1.3.0.tar.gz"
    sha256 "b3a79a23d37b5a02faa550b92cbbbebeb4aa1d77e649c3eb39c19abf5262da04"
  end

  resource "simplejson" do
    url "https://pypi.python.org/packages/source/s/simplejson/simplejson-3.6.5.tar.gz"
    sha256 "2a3189f79d1c7b8a2149a0e783c0b4217fad9b30a6e7d60450f2553dc2c0e57e"
  end

  def install
    # bug raised https://redmine.openinfosecfoundation.org/issues/1470
    ENV.deparallelize

    libnet = Formula["libnet"]
    libmagic = Formula["libmagic"]

    ENV.prepend_create_path "PYTHONPATH", libexec/"vendor/lib/python2.7/site-packages"
    resources.each do |r|
      r.stage do
        system "python", *Language::Python.setup_install_args(libexec/"vendor")
      end
    end

    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --with-libnet-includes=#{libnet.opt_include}
      --with-libnet-libs=#{libnet.opt_lib}
      --with-libmagic-includes=#{libmagic.opt_include}
      --with-libmagic-libraries=#{libmagic.opt_lib}
      ]

      args << "--enable-lua" if build.with? "lua"
      args << "--enable-luajit" if build.with? "luajit"

      if build.with? "geoip"
        geoip = Formula["geoip"]
        args << "--enable-geoip"
        args << "--with-libgeoip-includes=#{geoip.opt_include}"
        args << "--with-libgeoip-libs=#{geoip.opt_lib}"
      end

      if build.with? "jansson"
        jansson = Formula["jansson"]
        args << "--with-libjansson-includes=#{jansson.opt_include}"
        args << "--with-libjansson-libraries=#{jansson.opt_lib}"
      end

      system "./configure", *args
      system "make", "install-full"

      bin.env_script_all_files(libexec/"bin", :PYTHONPATH => ENV["PYTHONPATH"])

      # Leave the magic-file: prefix in otherwise it overrides a commented out line rather than intended line.
      inreplace etc/"suricata/suricata.yaml", %r{magic-file: /.+/magic}, "magic-file: #{libmagic.opt_share}/misc/magic"
  end

  test do
    assert_match(/#{version}/, shell_output("#{bin}/suricata --build-info"))
  end
end
