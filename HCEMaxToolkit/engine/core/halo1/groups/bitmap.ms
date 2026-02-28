bitmapSpritesFields = #(
    tagField \
        name:"bitmapIndex" \
        hidden:false \
        type:#int16, \
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
        count:4, \
    tagField \
        name:"left" \
        hidden:false \
        type:#float, \
    tagField \
        name:"right" \
        hidden:false \
        type:#float, \
    tagField \
        name:"top" \
        hidden:false \
        type:#float, \
    tagField \
        name:"bottom" \
        hidden:false \
        type:#float, \
    tagField \
        name:"registrationPoint" \
        hidden:false \
        type:#point2d
)

bitmapSpritesBlock = tagBlock \
    name:"spritesBlock" \
    length:32 \
    maximum:64 \
    fields:bitmapSpritesFields

bitmapSequencesFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"firstBitmapIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"bitmapCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:16, \
    tagField \
        name:"sprites" \
        hidden:false \
        type:#block \
        block:bitmapSpritesBlock
)

bitmapSequencesBlock = tagBlock \
    name:"sequencesBlock" \
    length:64 \
    maximum:256 \
    fields:bitmapSequencesFields

bitmapBitmapsFields = #(
    tagField \
        name:"signature" \
        hidden:false \
        type:#fourcc, \
    tagField \
        name:"width" \
        hidden:false \
        type:#int16 \
        unit:"pixels", \
    tagField \
        name:"height" \
        hidden:false \
        type:#int16 \
        unit:"pixels", \
    tagField \
        name:"depth" \
        hidden:false \
        type:#int16 \
        description:"depth is 1 for 2D textures and cube maps" \
        unit:"pixels", \
    tagField \
        name:"type" \
        hidden:false \
        type:#enum \
        description:"determines bitmap 'geometry'", \
    tagField \
        name:"format" \
        hidden:false \
        type:#enum \
        description:"determines how pixels are represented internally", \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"registrationPoint" \
        hidden:false \
        type:#point2d_int, \
    tagField \
        name:"mipmapCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"pixelsOffset" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:8
)

bitmapBitmapsBlock = tagBlock \
    name:"bitmapsBlock" \
    length:48 \
    maximum:2048 \
    fields:bitmapBitmapsFields

bitmapFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int16 \
        count:1, \
    tagField \
        name:"type" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"format" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"usage" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int16, \
    tagField \
        name:"detailFadeFactor" \
        hidden:false \
        type:#floatClamped \
        description:"0 means fade to gray by last mipmap, 1 means fade to gray by first mipmap" \
        unit:"[0,1]", \
    tagField \
        name:"sharpenAmount" \
        hidden:false \
        type:#floatClamped \
        description:"sharpens mipmap after downsampling" \
        unit:"[0,1]", \
    tagField \
        name:"bumpHeight" \
        hidden:false \
        type:#floatClamped \
        description:"the apparent height of the bump map above the triangle it is textured onto, in texture repeats (i.e., 1.0 would be as high as the texture is wide)" \
        unit:"repeats", \
    tagField \
        name:"spriteBudgetSize" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"spriteBudgetCount" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"colorPlateWidth" \
        hidden:false \
        type:#int16 \
        unit:"pixels", \
    tagField \
        name:"colorPlateHeight" \
        hidden:false \
        type:#int16 \
        unit:"pixels", \
    tagField \
        name:"compressedColorPlateData" \
        hidden:false \
        type:#tagData, \
    tagField \
        name:"processedPixelData" \
        hidden:false \
        type:#tagData, \
    tagField \
        name:"blurFilterSize" \
        hidden:false \
        type:#float \
        description:"blurs the bitmap before generating mipmaps" \
        unit:"[0,10] pixels", \
    tagField \
        name:"alphaBias" \
        hidden:false \
        type:#float \
        description:"affects alpha mipmap generation" \
        unit:"[-1,1]", \
    tagField \
        name:"mipmapCount" \
        hidden:false \
        type:#int16 \
        description:"0 defaults to all levels" \
        unit:"levels", \
    tagField \
        name:"spriteUsage" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"spriteSpacing" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"sequences" \
        hidden:false \
        type:#block \
        block:bitmapSequencesBlock, \
    tagField \
        name:"bitmaps" \
        hidden:false \
        type:#block \
        block:bitmapBitmapsBlock
)

bitmapBlock = tagBlock \
    name:"bitmapBlock" \
    length:108 \
    maximum:1 \
    fields:bitmapFields

bitmapDef = tagDef \
    fourcc:1651078253 \
    supergroup:undefined \
    tagBlock:bitmapBlock
