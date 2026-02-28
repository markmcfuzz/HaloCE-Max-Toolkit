hudMessageTextMessageelementsFields = #(
    tagField \
        name:"type" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"data" \
        hidden:false \
        type:#int8
)

hudMessageTextMessageelementsBlock = tagBlock \
    name:"messageElementsBlock" \
    length:2 \
    maximum:8192 \
    fields:hudMessageTextMessageelementsFields

hudMessageTextMessagesFields = #(
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"startIndexIntoTextBlob" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"startIndexOfMessageBlock" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"panelCount" \
        hidden:false \
        type:#int8, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:3, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:24
)

hudMessageTextMessagesBlock = tagBlock \
    name:"messagesBlock" \
    length:64 \
    maximum:1024 \
    fields:hudMessageTextMessagesFields

hudMessageTextFields = #(
    tagField \
        name:"textData" \
        hidden:false \
        type:#tagData, \
    tagField \
        name:"messageElements" \
        hidden:false \
        type:#block \
        block:hudMessageTextMessageelementsBlock, \
    tagField \
        name:"messages" \
        hidden:false \
        type:#block \
        block:hudMessageTextMessagesBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:84
)

hudMessageTextBlock = tagBlock \
    name:"hudMessageTextBlock" \
    length:128 \
    maximum:1 \
    fields:hudMessageTextFields

hudMessageTextDef = tagDef \
    fourcc:1752003616 \
    supergroup:undefined \
    tagBlock:hudMessageTextBlock
