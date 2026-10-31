------------------------------------------------------------------------------
--	Copyright (C) 2025 - Present Mark McFuzz (mailto:mark.mcfuzz@gmail.com)
--	This program is free software; you can redistribute it and/or modify it
--	under the terms of the GNU General Public License as published by the
--	Free Software Foundation; either version 2 of the License, or (at your
--	option) any later version. This program is distributed in the hope that
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
--	the GNU General Public License for more details. A full copy of this
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------

-- Explicit normals of a whole mesh in one go, through the 3ds Max .NET API (Autodesk.Max).
-- setNormal / Edit_Normals cost one call per vertex or corner; these copy whole arrays.
-- The .NET wrapper names some members differently: Mesh__TriObject, INativeObject__NativePointer.

global meshNormalsMaxGlobal = undefined

-- .NET array of n elements kept as a dotNetObject (not turned into a MAXScript array)
fn meshNormalsNetArray typeName n =
(
	local a = try (dotNetObject (typeName + "[]") n) catch undefined
	if a == undefined then
		a = (dotNetClass "System.Array").CreateInstance (dotNetClass typeName) n asDotNetObject:true
	a
)

-- .NET Mesh of a node: its base object, or the evaluated result of the whole modifier stack
fn meshNormalsNetMesh obj evaluated:false =
(
	if meshNormalsMaxGlobal == undefined then
		meshNormalsMaxGlobal = (dotNetClass "Autodesk.Max.GlobalInterface").Instance
	local g = meshNormalsMaxGlobal
	local inode = g.COREInterface.GetINodeByHandle obj.inode.handle
	if evaluated then
	(
		local os = inode.EvalWorldState currentTime.ticks true
		(os.Obj.ConvertToType currentTime.ticks g.TriObjectClassID).Mesh__TriObject
	)
	else
		(inode.ObjectRef.FindBaseObject()).Mesh__TriObject
)

-- Gives every face corner of an Editable Mesh (no modifiers) its own explicit normal, as
-- setNormal does: faces = Point3 vertex indices, vertNormals = Point3 per vertex.
fn meshNormalsSetPerCorner meshObj faces vertNormals =
(
	local faceCount = faces.count
	local values = #()
	values.count = faceCount * 9
	local ids = #()
	ids.count = faceCount * 4
	local k = 0
	for f = 1 to faceCount do
	(
		local face = faces[f]
		for c = 1 to 3 do
		(
			local n = vertNormals[face[c]]
			values[k * 3 + 1] = n.x
			values[k * 3 + 2] = n.y
			values[k * 3 + 3] = n.z
			k += 1
		)
		-- MeshNormalFace: 3 normal ids + "specified" bits (one per corner)
		local i = (f - 1) * 4
		ids[i + 1] = k - 3
		ids[i + 2] = k - 2
		ids[i + 3] = k - 1
		ids[i + 4] = 7
	)

	local msh = meshNormalsNetMesh meshObj
	msh.SpecifyNormals()
	local spec = msh.SpecifiedNormals
	spec.SetParent msh
	spec.SetNumNormals (faceCount * 3)
	spec.SetNumFaces faceCount
	local marshal = dotNetClass "System.Runtime.InteropServices.Marshal"
	marshal.Copy (dotNet.ValueToDotNetObject values (dotNetClass "System.Single[]")) 0 spec.NormalArray.INativeObject__NativePointer values.count
	marshal.Copy (dotNet.ValueToDotNetObject ids (dotNetClass "System.Int32[]")) 0 spec.FaceArray.INativeObject__NativePointer ids.count
	spec.SetAllExplicit true
	-- Same flags setNormal leaves (bits 0, 1, 3)
	for b = 0 to 30 do spec.SetFlag (bit.shift 1 b) (b == 0 or b == 1 or b == 3)
	msh.InvalidateGeomCache()
	update meshObj
)

-- Explicit normals for a new Editable Mesh, like setNormal on every vertex but in one go.
-- Falls back to setNormal when the mesh lost faces or the .NET API fails.
fn meshNormalsApply meshObj faces vertNormals =
(
	local written = faces.count == meshObj.numfaces and \
		(try (meshNormalsSetPerCorner meshObj faces vertNormals; true) catch
		(
			logger.warn "Normals could not be written in one go ({}), using setNormal" args:#(getCurrentException())
			false
		))
	if not written then
		for v = 1 to vertNormals.count do setNormal meshObj v vertNormals[v]
	ok
)

-- Saves the normals of obj's evaluated mesh to a file: float x,y,z per normal, then per face
-- 3 normal ids (0-based) + specified bits (int32). Returns #(normalCount, faceCount).
fn meshNormalsSave obj path =
(
	local spec = (meshNormalsNetMesh obj evaluated:true).SpecifiedNormals
	if spec == undefined then return undefined
	local normalBytes = spec.NumNormals * 12
	local faceBytes = spec.NumFaces * 16
	local buffer = meshNormalsNetArray "System.Byte" (normalBytes + faceBytes)
	local marshal = dotNetClass "System.Runtime.InteropServices.Marshal"
	if normalBytes > 0 then marshal.Copy spec.NormalArray.INativeObject__NativePointer buffer 0 normalBytes
	if faceBytes > 0 then marshal.Copy spec.FaceArray.INativeObject__NativePointer buffer normalBytes faceBytes
	(dotNetClass "System.IO.File").WriteAllBytes path buffer
	#(spec.NumNormals, spec.NumFaces)
)

scriptName = getFilenameFile (getThisScriptFilename()) + getFilenameType (getThisScriptFilename())
logger.info "{} loaded." args:#(scriptName)
