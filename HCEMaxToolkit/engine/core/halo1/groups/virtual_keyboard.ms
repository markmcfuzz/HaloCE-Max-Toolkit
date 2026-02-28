virtualKeyboardVirtualkeysFields = #(
    tagField \
        name:"keyboardKey" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"lowercaseCharacter" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"shiftCharacter" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"capsCharacter" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"symbolsCharacter" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"shiftCapsCharacter" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"shiftSymbolsCharacter" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"capsSymbolsCharacter" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unselectedBackgroundBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"selectedBackgroundBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"activeBackgroundBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"stickyBackgroundBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap)
)

virtualKeyboardVirtualkeysBlock = tagBlock \
    name:"virtualKeysBlock" \
    length:80 \
    maximum:44 \
    fields:virtualKeyboardVirtualkeysFields

virtualKeyboardFields = #(
    tagField \
        name:"displayFont" \
        hidden:false \
        type:#tagReference \
        allowed:#(#font), \
    tagField \
        name:"backgroundBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"specialKeyLabelsStringList" \
        hidden:false \
        type:#tagReference \
        allowed:#(#unicode_string_list), \
    tagField \
        name:"virtualKeys" \
        hidden:false \
        type:#block \
        block:virtualKeyboardVirtualkeysBlock
)

virtualKeyboardBlock = tagBlock \
    name:"virtualKeyboardBlock" \
    length:60 \
    maximum:1 \
    fields:virtualKeyboardFields

virtualKeyboardDef = tagDef \
    fourcc:1986227065 \
    supergroup:undefined \
    tagBlock:virtualKeyboardBlock
