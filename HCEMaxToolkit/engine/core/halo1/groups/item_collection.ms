itemCollectionItempermutationsFields = #(
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"weight" \
        hidden:false \
        type:#float \
        description:"relatively how likely this item will be chosen", \
    tagField \
        name:"item" \
        hidden:false \
        type:#tagReference \
        description:"which item to " \
        allowed:#(#item), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32
)

itemCollectionItempermutationsBlock = tagBlock \
    name:"itemPermutationsBlock" \
    length:84 \
    maximum:32 \
    fields:itemCollectionItempermutationsFields

itemCollectionFields = #(
    tagField \
        name:"itemPermutations" \
        hidden:false \
        type:#block \
        block:itemCollectionItempermutationsBlock, \
    tagField \
        name:"spawnTime(inSeconds,0=Default)" \
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
        count:76
)

itemCollectionBlock = tagBlock \
    name:"itemCollectionBlock" \
    length:92 \
    maximum:1 \
    fields:itemCollectionFields

itemCollectionDef = tagDef \
    fourcc:1769237859 \
    supergroup:undefined \
    tagBlock:itemCollectionBlock
