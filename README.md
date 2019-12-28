
# classimp


common lisp/cffi bindings for Open Asset Import Library (http://www.assimp.org/)
(https://github.com/assimp/assimp)

Should support assimp versions 4.0 to 4.1. Version to support is
determined by querying c library at compile time (or load if not
previously compiled), with errors if versions don't match at load or
runtime. (Current assimp from git will be detected as 5.0, but isn't
completely binary compatible so might have problems)


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



27 December 2019

A brief note about this fork:

The original classimp repo hasn't been updated since 2017. The only
modifications done here facilitated it running on a local machine with
libassimp4.1.  Other changes may be made to "bring it up to speed" (we actually
have libassimp5x available and that's next) ... then again they may not.

We're sharing it here in case someone else runs into the same speedbumps we did.
;)

