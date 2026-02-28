shaderFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"detailLevel" \
        hidden:false \
        type:#enum \
        description:"affects the density of tesselation (high means slow).", \
    tagField \
        name:"power" \
        hidden:false \
        type:#float \
        description:"power of emitted light from 0 to infinity", \
    tagField \
        name:"colorOfEmittedLight" \
        hidden:false \
        type:#colorRGB, \
    tagField \
        name:"tintColor" \
        hidden:false \
        type:#colorRGB \
        description:"light passing through this surface (if it's transparent) will be tinted this color.", \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"materialType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2
)

shaderBlock = tagBlock \
    name:"shaderBlock" \
    length:40 \
    maximum:1 \
    fields:shaderFields

shaderDef = tagDef \
    fourcc:1936221298 \
    supergroup:undefined \
    tagBlock:shaderBlock
