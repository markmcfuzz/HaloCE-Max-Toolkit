multiplayerScenarioDescriptionMultiplayerscenariosFields = #(
    tagField \
        name:"descriptiveBitmap" \
        hidden:false \
        type:#tagReference \
        allowed:#(#bitmap), \
    tagField \
        name:"displayedMapName" \
        hidden:false \
        type:#tagReference \
        allowed:#(#unicode_string_list), \
    tagField \
        name:"scenarioTagDirectoryPath" \
        hidden:false \
        type:#string \
        description:"this is the path to the directory containing the scenario tag file of the same name", \
    tagField \
        name:"unnamed" \
        hidden:false \
        type:#padding \
        size:#int8 \
        count:4
)

multiplayerScenarioDescriptionMultiplayerscenariosBlock = tagBlock \
    name:"multiplayerScenariosBlock" \
    length:68 \
    maximum:32 \
    fields:multiplayerScenarioDescriptionMultiplayerscenariosFields

multiplayerScenarioDescriptionFields = #(
    tagField \
        name:"multiplayerScenarios" \
        hidden:false \
        type:#block \
        block:multiplayerScenarioDescriptionMultiplayerscenariosBlock
)

multiplayerScenarioDescriptionBlock = tagBlock \
    name:"multiplayerScenarioDescriptionBlock" \
    length:12 \
    maximum:1 \
    fields:multiplayerScenarioDescriptionFields

multiplayerScenarioDescriptionDef = tagDef \
    fourcc:1836084345 \
    supergroup:undefined \
    tagBlock:multiplayerScenarioDescriptionBlock
