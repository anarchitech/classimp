# classimp


# Deprecated: 12.05.2024

**Unmaintained, do not use, slated for deletion in 90 days**

The original [classimp repo](https://github.com/3b/classimp) finally 
update the bindings last year for assimp-5.2.5 among several other
tweaks, so run that and beat it into submission for your projects.

We'll be deleting this incredibly high traffic repository within 90-ish 
days of the above date, (that's May 05 for Les Américains lurking out 
there.)

---

[Common Lisp](https://common-lisp.net/) / [CFFI](https://common-lisp.net/project/cffi/) bindings for the [Open Asset Import Library](http://www.assimp.org/).  
assimp repo [here.](https://github.com/assimp/assimp)

**This fork currently supports libassimp4.1. Versions below this are not supported.**
 
**If you need 3.0-3.3 support only**, clone or fork the [original repo](https://github.com/3b/classimp).

**If you are running a mix of versions** in your lab that require 3.0-4.1, try using [detvdl's](https://github.com/detvdl/classimp) flavor that's been sitting as a PR
in the main repo for 2+ years now with no merge. (For 'reasons' we had no need/interest in supporting older versions for our purposes.)

Version to support is determined by querying c library at compile time (or load if not
previously compiled), with errors if versions don't match at load or
runtime. 

Allows (among other things) loading of the following formats:

    Collada ( .dae )
    Blender 3D ( .blend )
    3ds Max 3DS ( .3ds )
    3ds Max ASE ( .ase )
    Wavefront Object ( .obj )
    Industry Foundation Classes (IFC/Step) ( .ifc )
    XGL ( .xgl,.zgl )
    Stanford Polygon Library ( .ply )
    *AutoCAD DXF ( .dxf )
    LightWave ( .lwo )
    LightWave Scene ( .lws )
    Modo ( .lxo )
    Stereolithography ( .stl )
    DirectX X ( .x )
    AC3D ( .ac )
    Milkshape 3D ( .ms3d )
    * TrueSpace ( .cob,.scn )



**27 December 2019**

**A brief note about this fork:**

The [original classimp repo](https://github.com/3b/classimp) hasn't been updated since 2017. The only
modifications here facilitated running it on a local machine with
libassimp4.1.  Other changes may be forthcoming ...

We're sharing it here in case someone else runs into the same speedbumps we did.
;)  If you're playing along with some of [cbaggers](https://github.com/cbaggers/) fun [youtube efforts](https://www.youtube.com/watch?v=82o5NeyZtvw) and running a current build of your os of choice/lisp you'll undoubtedly need to do something similar.

**A brief note about cloning/installation:**

1) Some basic assumptions: sbcl, vim+slimv or emacs+slime, quicklisp.
2) Clone this repo in ~/quicklisp/local-projects/classimp
3) sbcl prompt: CL-USER> (ql:quickload :classimp) (or substitute 'classimp'
   for whatever project you're loading up that calls 'classimp')

**Current Builds**

Currently we have this built, tested and running on latest versions of
SBCL and Quicklisp on the following systems:

* OpenBSD --current AMD64
* NixOS --stable 5.4.8 kernel (various platforms)
* Debian (various distros, various platforms)
* Archinux (various platforms)
* ChromeOS (Intel platforms)
