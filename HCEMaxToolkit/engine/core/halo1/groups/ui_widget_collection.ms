uiWidgetCollectionUiwidgetdefinitionsFields = #(
    tagField \
        name:"uiWidgetDefinition" \
        hidden:false \
        type:#tagReference \
        allowed:#(#ui_widget_definition)
)

uiWidgetCollectionUiwidgetdefinitionsBlock = tagBlock \
    name:"uiWidgetDefinitionsBlock" \
    length:16 \
    maximum:32 \
    fields:uiWidgetCollectionUiwidgetdefinitionsFields

uiWidgetCollectionFields = #(
    tagField \
        name:"uiWidgetDefinitions" \
        hidden:false \
        type:#block \
        block:uiWidgetCollectionUiwidgetdefinitionsBlock
)

uiWidgetCollectionBlock = tagBlock \
    name:"uiWidgetCollectionBlock" \
    length:12 \
    maximum:1 \
    fields:uiWidgetCollectionFields

uiWidgetCollectionDef = tagDef \
    fourcc:1399813484 \
    supergroup:undefined \
    tagBlock:uiWidgetCollectionBlock
