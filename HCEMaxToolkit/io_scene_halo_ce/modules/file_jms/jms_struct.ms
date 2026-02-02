------------------------------------------------------------------------------------------------
--	Copyright (C) 2025 Mark McFuzz (mailto:mark.mcfuzz@gmail.com)				
--	This program is free software; you can redistribute it and/or modify it	
--	under the terms of the GNU General Public License as published by the	
--	Free Software Foundation; either version 2 of the License, or (at your	
--	option) any later version. This program is distributed in the hope that	
--	it will be useful, but WITHOUT ANY WARRANTY; without even the implied	
--	warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See	
--	the GNU General Public License for more details. A full copy of this	
--	license is available at http://www.gnu.org/licenses/gpl.txt.
------------------------------------------------------------------------------------------------

struct jmsFile
(	
	jmsVersion = undefined,
	jmsChecksum = undefined,
	nodeCount = undefined,
	nodes = #(),
	shaderCount = undefined,
	shaders = #(),
	markerCount = undefined,
	markers = #(),
	regionCount = undefined,
	regions = #(),
	vertexCount = undefined,
	vertices = #(),
	triangleCount = undefined,
	triangles = #(),
	smoothingGroups = #(),
	useSimpleHierarchy = false  -- Flag for fbx-to-jms format
)

struct nodes
(	
	nodeName,
	firstChildNodeIndex,
	nextSiblingNodeIndex,
	nodeRotation,
	nodeTranslation
)

struct shaders
(	
	shaderName,
	bitmapPath
)

struct markers
(	
	markerName,
	markerRegion,
	parentNodeIndex,
	markerRotation,
	markerTranslation,
	markerRadius
)

struct region
(	
	regionName
)

struct vertices
(	
	node0Index,
	position,
	normal,
	node1Index,
	node1Weight,
	texturePos
)

struct triangles
(	
	regionIndex,
	shaderIndex,
	vertexIndices
)

logger "JMS structure loaded.\n" logType: #success 