fontCharactertableFields = #(
    tagField \
        name:"characterIndex" \
        hidden:false \
        type:#index
)

fontCharactertableBlock = tagBlock \
    name:"characterTableBlock" \
    length:2 \
    maximum:256 \
    fields:fontCharactertableFields

fontCharactertablesFields = #(
    tagField \
        name:"characterTable" \
        hidden:false \
        type:#block \
        block:fontCharactertableBlock
)

fontCharactertablesBlock = tagBlock \
    name:"characterTablesBlock" \
    length:12 \
    maximum:256 \
    fields:fontCharactertablesFields

fontCharactersFields = #(
    tagField \
        name:"character" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"characterWidth" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"bitmapWidth" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"bitmapHeight" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"bitmapOriginX" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"bitmapOriginY" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"hardwareCharacterIndex" \
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
        type:#int32
)

fontCharactersBlock = tagBlock \
    name:"charactersBlock" \
    length:20 \
    maximum:32000 \
    fields:fontCharactersFields

fontFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#int32, \
    tagField \
        name:"ascendingHeight" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"decendingHeight" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"leadingHeight" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"leadinWidth" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:36, \
    tagField \
        name:"characterTables" \
        hidden:false \
        type:#block \
        block:fontCharactertablesBlock, \
    tagField \
        name:"bold" \
        hidden:false \
        type:#tagReference \
        allowed:#(#font), \
    tagField \
        name:"italic" \
        hidden:false \
        type:#tagReference \
        allowed:#(#font), \
    tagField \
        name:"condense" \
        hidden:false \
        type:#tagReference \
        allowed:#(#font), \
    tagField \
        name:"underline" \
        hidden:false \
        type:#tagReference \
        allowed:#(#font), \
    tagField \
        name:"characters" \
        hidden:false \
        type:#block \
        block:fontCharactersBlock, \
    tagField \
        name:"pixels" \
        hidden:false \
        type:#tagData
)

fontBlock = tagBlock \
    name:"fontBlock" \
    length:156 \
    maximum:1 \
    fields:fontFields

fontDef = tagDef \
    fourcc:1718578804 \
    supergroup:undefined \
    tagBlock:fontBlock
