require 'formula'

class Ffmpeg < Formula
  homepage 'http://ffmpeg.org/'
  url 'http://ffmpeg.org/releases/ffmpeg-1.2.4.tar.bz2'
  sha1 'ee73a05bde209fc23441c7e49767c1b7a4b6f124'

  head 'git://git.videolan.org/ffmpeg.git'

  # This is actually the new stable, not a devel release,
  # but not everything builds with it yet - notably gpac
  devel do
    url 'http://ffmpeg.org/releases/ffmpeg-2.1.1.tar.bz2'
    sha1 'e7a5b2d7f702c4e9ca69e23c6d3527f93de0d1bd'

    depends_on 'libbluray' => :optional
    depends_on 'libquvi' => :optional
  end

  option "without-x264", "Disable H.264 encoder"
  option "without-lame", "Disable MP3 encoder"
  option "without-xvid", "Disable Xvid MPEG-4 video encoder"

  option "with-rtmpdump", "Enable RTMP protocol"
  option "with-libvo-aacenc", "Enable VisualOn AAC encoder"
  option "with-libass", "Enable ASS/SSA subtitle format"
  option "with-openjpeg", 'Enable JPEG 2000 image format'
  option 'with-openssl', 'Enable SSL support'
  option 'with-schroedinger', 'Enable Dirac video format'
  option 'with-ffplay', 'Enable FFplay media player'
  option 'with-tools', 'Enable additional FFmpeg tools'
  option 'with-fdk-aac', 'Enable the Fraunhofer FDK AAC library'

  depends_on 'pkg-config' => :build

  # manpages won't be built without texi2html
  depends_on 'texi2html' => :build if MacOS.version >= :mountain_lion
  depends_on 'yasm' => :build

  depends_on 'x264' => :recommended
  depends_on 'faac' => :recommended
  depends_on 'lame' => :recommended
  depends_on 'xvid' => :recommended

  depends_on :freetype => :optional
  depends_on 'theora' => :optional
  depends_on 'libvorbis' => :optional
  depends_on 'libvpx' => :optional
  depends_on 'rtmpdump' => :optional
  depends_on 'opencore-amr' => :optional
  depends_on 'libvo-aacenc' => :optional
  depends_on 'libass' => :optional
  depends_on 'openjpeg' => :optional
  depends_on 'sdl' if build.include? 'with-ffplay'
  depends_on 'speex' => :optional
  depends_on 'schroedinger' => :optional
  depends_on 'fdk-aac' => :optional
  depends_on 'opus' => :optional
  depends_on 'frei0r' => :optional
  depends_on 'libcaca' => :optional

  # Fix build against freetype 2.5.1
  # http://ffmpeg.org/pipermail/ffmpeg-devel/2013-November/151404.html
  def patches; DATA; end unless build.head?

  def install
    # Remove when fix for freetype 2.5.1+ is incorporated upstream
    inreplace 'configure', 'ft2build.h freetype/freetype.h', 'ft2build.h freetype.h'

    args = ["--prefix=#{prefix}",
            "--enable-shared",
            "--enable-pthreads",
            "--enable-gpl",
            "--enable-version3",
            "--enable-nonfree",
            "--enable-hardcoded-tables",
            "--enable-avresample",
            "--enable-vda",
            "--cc=#{ENV.cc}",
            "--host-cflags=#{ENV.cflags}",
            "--host-ldflags=#{ENV.ldflags}"
           ]

    args << "--enable-libx264" if build.with? 'x264'
    args << "--enable-libfaac" if build.with? 'faac'
    args << "--enable-libmp3lame" if build.with? 'lame'
    args << "--enable-libxvid" if build.with? 'xvid'

    args << "--enable-libfreetype" if build.with? 'freetype'
    args << "--enable-libtheora" if build.with? 'theora'
    args << "--enable-libvorbis" if build.with? 'libvorbis'
    args << "--enable-libvpx" if build.with? 'libvpx'
    args << "--enable-librtmp" if build.with? 'rtmpdump'
    args << "--enable-libopencore-amrnb" << "--enable-libopencore-amrwb" if build.with? 'opencore-amr'
    args << "--enable-libvo-aacenc" if build.with? 'libvo-aacenc'
    args << "--enable-libass" if build.with? 'libass'
    args << "--enable-ffplay" if build.include? 'with-ffplay'
    args << "--enable-libspeex" if build.with? 'speex'
    args << '--enable-libschroedinger' if build.with? 'schroedinger'
    args << "--enable-libfdk-aac" if build.with? 'fdk-aac'
    args << "--enable-openssl" if build.with? 'openssl'
    args << "--enable-libopus" if build.with? 'opus'
    args << "--enable-frei0r" if build.with? 'frei0r'
    args << "--enable-libcaca" if build.with? 'libcaca'
    args << "--enable-libquvi" if build.with? 'libquvi'

    if build.with? 'openjpeg'
      args << '--enable-libopenjpeg'
      args << '--extra-cflags=' + %x[pkg-config --cflags libopenjpeg].chomp
    end

    # For 32-bit compilation under gcc 4.2, see:
    # http://trac.macports.org/ticket/20938#comment:22
    ENV.append_to_cflags "-mdynamic-no-pic" if Hardware.is_32_bit? && Hardware::CPU.intel? && ENV.compiler == :clang

    system "./configure", *args

    if MacOS.prefer_64_bit?
      inreplace 'config.mak' do |s|
        shflags = s.get_make_var 'SHFLAGS'
        if shflags.gsub!(' -Wl,-read_only_relocs,suppress', '')
          s.change_make_var! 'SHFLAGS', shflags
        end
      end
    end

    system "make install"

    if build.include? 'with-tools'
      system "make alltools"
      bin.install Dir['tools/*'].select {|f| File.executable? f}
    end
  end

end

__END__
diff --git a/libavfilter/vf_drawtext.c b/libavfilter/vf_drawtext.c
index 2358e35..4c08092 100644
--- a/libavfilter/vf_drawtext.c
+++ b/libavfilter/vf_drawtext.c
@@ -48,7 +48,6 @@
 #include "video.h"
 
 #include <ft2build.h>
-#include <freetype/config/ftheader.h>
 #include FT_FREETYPE_H
 #include FT_GLYPH_H
 #if CONFIG_FONTCONFIG

