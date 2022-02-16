[SettingsTab name="Customization"]
void RenderSettingsCustomization(){

    if(!UserCanUseThePlugin()){
        UI::Text("You don't have the required permissions to use this plugin. You need at least the standard edition.");
        return;
    }

    UI::Text("\tRefresh");
    if(UI::Button("Refresh now")){
        refreshPosition = true;
    }

    UI::Text("\tTimer");

    refreshTimer = UI::InputInt("Refresh timer every X (minutes)", refreshTimer);

    UI::Text("\n\tPersonal best");

    showPb = UI::Checkbox("Show personal best", showPb);

    UI::Text("\n\tTime difference");
    showTimeDifference = UI::Checkbox("Show time difference", showTimeDifference);
    if(showTimeDifference){
        inverseTimeDiffSign = UI::Checkbox("Inverse sign (+ instead of -)", inverseTimeDiffSign);

        UI::Text("\t\tFrom which position should the time difference be shown?");
        string comboText = "";
        if(currentComboChoice == -1){
            comboText = "Personal best";
        }else{
            comboText = "Position " + currentComboChoice;
        }

        if(UI::BeginCombo("Time Diff position", comboText)){
            if(UI::Selectable("Personal best", currentComboChoice == -1)){
                currentComboChoice = -1;
                UI::SetItemDefaultFocus();
            }
            for(int i = 0; i < int(allPositionToGet.Length); i++){
                string text = "Position " + allPositionToGet[i];
                if(UI::Selectable(text, currentComboChoice == allPositionToGet[i])){
                    currentComboChoice = allPositionToGet[i];
                }
            }
            UI::EndCombo();
        }
            

    }
    

    UI::Text("\n\tPositions customizations");

    UI::Text("It will update the UI when the usual conditions are met (see Explanation) or if you press the refresh button.");

    if(UI::Button("Reset to default")){
        allPositionToGet = {1,10,100,1000,10000};
        allPositionToGetStringSave = "1,10,100,1000,10000";
        nbSizePositionToGetArray = 5;
    }

    for(int i = 0; i < nbSizePositionToGetArray; i++){
        int tmp = UI::InputInt("Custom position " + (i+1), allPositionToGet[i]);
        if(tmp != allPositionToGet[i]){
            if(currentComboChoice == allPositionToGet[i]){
                currentComboChoice = tmp;
            }
            allPositionToGet[i] = tmp;
            OnSettingsChanged();
        }
    }


    if(UI::Button("+ : Add a position")){
        nbSizePositionToGetArray++;
        allPositionToGet.InsertLast(1);
        OnSettingsChanged();
    }
    if(UI::Button("- : Remove a position")){
        if(nbSizePositionToGetArray > 1){
            nbSizePositionToGetArray--;
            allPositionToGet.RemoveAt(nbSizePositionToGetArray);
            OnSettingsChanged();
        }
    }
}

[SettingsTab name="Explanation"]
void RenderSettingsExplanation(){
    UI::Text("This plugin allows you to see more leaderbaord position.\n\n");
    UI::Text("You can modify the positions in the \"Customization tab\"\n");
    UI::Text("The leaderboard is refreshed every " + refreshTimer + " minutes when in a map.");
    UI::Text("This timer resets when you leave the map.");
    UI::Text("It is also automatically refreshed when you join a map, or if you set a new pb on a map.");;
    UI::Text("\nThe plugin also allows you to see the time difference between a given position and all the other one.");
    UI::Dummy(vec2(0,150));
    UI::Text("Made by Banalian.\nContact me on Discord (you can find me on the OpenPlanet Discord) if you have any questions or suggestions !\nYou can also use the github page to post about any issue you might encounter.");
}