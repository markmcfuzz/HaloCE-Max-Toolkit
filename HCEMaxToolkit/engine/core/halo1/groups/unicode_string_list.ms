unicodeStringListStringreferencesFields = #(
    tagField \
        name:"string" \
        hidden:false \
        type:#tagData
)

unicodeStringListStringreferencesBlock = tagBlock \
    name:"stringReferencesBlock" \
    length:20 \
    maximum:800 \
    fields:unicodeStringListStringreferencesFields

unicodeStringListFields = #(
    tagField \
        name:"stringReferences" \
        hidden:false \
        type:#block \
        block:unicodeStringListStringreferencesBlock
)

unicodeStringListBlock = tagBlock \
    name:"unicodeStringListBlock" \
    length:12 \
    maximum:1 \
    fields:unicodeStringListFields

unicodeStringListDef = tagDef \
    fourcc:1970500722 \
    supergroup:undefined \
    tagBlock:unicodeStringListBlock
