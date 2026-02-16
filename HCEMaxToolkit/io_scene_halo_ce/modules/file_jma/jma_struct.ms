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

struct jmaFile
(	
	jmaVersion = undefined,
	frameCount = undefined,
	frameRate = undefined,
	actorNamesIndex = undefined,
	actorNames = undefined,
	nodeCount = undefined,
	nodeChecksum = undefined,
	nodes = #(),
    keyframes = #(),      -- Used by exporter (jmaKeyframes array)
    frames = #()          -- Used by importer (jmaFrameData array)
)

struct jmaNodes
(	
	nodeName,
	firstChildNodeIndex,
	nextSiblingNodeIndex
)

-- Used by exporter: stores arrays per frame (one element per node)
struct jmaKeyframes 
(	
    nodeTranslation,
    nodeRotation,
    nodeScale
)

-- Used by importer: stores single node transform for one frame
struct jmaNodeFrame
(
    translation,
    rotation,
    scale
)

-- Used by importer: stores all node data for one frame
struct jmaFrameData
(
    nodeFrames = #()  -- Array of jmaNodeFrame
)

logger "JMA structure loaded.\n" logType: #success 