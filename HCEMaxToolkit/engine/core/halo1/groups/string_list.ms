stringListStringreferencesFields = #(
    tagField \
        name:"string" \
        hidden:false \
        type:#tagData
)

stringListStringreferencesBlock = tagBlock \
    name:"stringReferencesBlock" \
    length:20 \
    maximum:800 \
    fields:stringListStringreferencesFields

stringListFields = #(
    tagField \
        name:"stringReferences" \
        hidden:false \
        type:#block \
        block:stringListStringreferencesBlock
)

stringListBlock = tagBlock \
    name:"stringListBlock" \
    length:12 \
    maximum:1 \
    fields:stringListFields

stringListDef = tagDef \
    fourcc:1937011235 \
    supergroup:undefined \
    tagBlock:stringListBlock
