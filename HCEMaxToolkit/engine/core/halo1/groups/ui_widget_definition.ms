uiWidgetDefinitionGamedatainputsFields = #(
    tagField \
        name:"function" \
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
        count:32
)

uiWidgetDefinitionGamedatainputsBlock = tagBlock \
    name:"gameDataInputsBlock" \
    length:36 \
    maximum:64 \
    fields:uiWidgetDefinitionGamedatainputsFields

uiWidgetDefinitionEventhandlersFields = #(
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"eventType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"function" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"widgetTag" \
        hidden:false \
        type:#tagReference \
        allowed:#(#ui_widget_definition), \
    tagField \
        name:"soundEffect" \
        hidden:false \
        type:#tagReference \
        allowed:#(#sound), \
    tagField \
        name:"script" \
        hidden:false \
        type:#string
)

uiWidgetDefinitionEventhandlersBlock = tagBlock \
    name:"eventHandlersBlock" \
    length:72 \
    maximum:32 \
    fields:uiWidgetDefinitionEventhandlersFields

uiWidgetDefinitionSearchandreplacefunctionsFields = #(
    tagField \
        name:"searchString" \
        hidden:false \
        type:#string, \
    tagField \
        name:"replaceFunction" \
        hidden:false \
        type:#enum
)

uiWidgetDefinitionSearchandreplacefunctionsBlock = tagBlock \
    name:"searchAndReplaceFunctionsBlock" \
    length:34 \
    maximum:32 \
    fields:uiWidgetDefinitionSearchandreplacefunctionsFields

uiWidgetDefinitionConditionalwidgetsFields = #(
    tagField \
        name:"widgetTag" \
        hidden:false \
        type:#tagReference \
        allowed:#(#ui_widget_definition), \
    tagField \
        name:"name(unused)" \
        hidden:false \
        type:#string, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"customControllerIndex(unused)" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:26
)

uiWidgetDefinitionConditionalwidgetsBlock = tagBlock \
    name:"conditionalWidgetsBlock" \
    length:80 \
    maximum:32 \
    fields:uiWidgetDefinitionConditionalwidgetsFields

uiWidgetDefinitionChildwidgetsFields = #(
    tagField \
        name:"widgetTag" \
        hidden:false \
        type:#tagReference \
        allowed:#(#ui_widget_definition), \
    tagField \
        name:"name(unused)" \
        hidden:false \
        type:#string, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"customControllerIndex" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"verticalOffset" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"horizontalOffset" \
        hidden:false \
        type:#int16, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:22
)

uiWidgetDefinitionChildwidgetsBlock = tagBlock \
    name:"childWidgetsBlock" \
    length:80 \
    maximum:32 \
    fields:uiWidgetDefinitionChildwidgetsFields

uiWidgetDefinitionFields = #(
    tagField \
        name:"widgetType" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"controllerIndex" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"name" \
        hidden:false \
        type:#string, \
    tagField \
        name:"bounds" \
        hidden:false \
        type:#rectangle, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"millisecondsToAutoClose" \
        hidden:false \
        type:#int32 \
        description:"<=0 to never auto-close", \
    tagField \
        name:"millisecondsAutoCloseFadeTime" \
        hidden:false \
        type:#int32 \
        description:"<= 0 for immediate close", \
    tagField \
        name:"backgroundBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"gameDataInputs" \
        hidden:false \
        type:#block \
        block:uiWidgetDefinitionGamedatainputsBlock, \
    tagField \
        name:"eventHandlers" \
        hidden:false \
        type:#block \
        block:uiWidgetDefinitionEventhandlersBlock, \
    tagField \
        name:"searchAndReplaceFunctions" \
        hidden:false \
        type:#block \
        block:uiWidgetDefinitionSearchandreplacefunctionsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:128, \
    tagField \
        name:"textLabelUnicodeStringsList" \
        hidden:false \
        type:#tagReference \
        allowed:#(#unicode_string_list), \
    tagField \
        name:"textFont" \
        hidden:false \
        type:#tagReference \
        allowed:#(#font), \
    tagField \
        name:"textColor" \
        hidden:false \
        type:#colorARGB, \
    tagField \
        name:"justification" \
        hidden:false \
        type:#enum, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:12, \
    tagField \
        name:"stringListIndex" \
        hidden:false \
        type:#int16 \
        description:"default is 0", \
    tagField \
        name:"horizOffset" \
        hidden:false \
        type:#int16 \
        description:"offsets text position in its bounding area", \
    tagField \
        name:"vertOffset" \
        hidden:false \
        type:#int16 \
        description:"offsets the text position in its bounding area", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:26, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:2, \
    tagField \
        name:"flags" \
        hidden:false \
        type:#bitfield \
        size:#int32, \
    tagField \
        name:"listHeaderBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"listFooterBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"headerBounds" \
        hidden:false \
        type:#rectangle, \
    tagField \
        name:"footerBounds" \
        hidden:false \
        type:#rectangle, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"extendedDescriptionWidget" \
        hidden:false \
        type:#tagReference \
        allowed:#(#ui_widget_definition), \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:32, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:256, \
    tagField \
        name:"conditionalWidgets" \
        hidden:false \
        type:#block \
        block:uiWidgetDefinitionConditionalwidgetsBlock, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:128, \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:128, \
    tagField \
        name:"childWidgets" \
        hidden:false \
        type:#block \
        block:uiWidgetDefinitionChildwidgetsBlock
)

uiWidgetDefinitionBlock = tagBlock \
    name:"uiWidgetDefinitionBlock" \
    length:1004 \
    maximum:1 \
    fields:uiWidgetDefinitionFields

uiWidgetDefinitionDef = tagDef \
    fourcc:1147489377 \
    supergroup:undefined \
    tagBlock:uiWidgetDefinitionBlock
