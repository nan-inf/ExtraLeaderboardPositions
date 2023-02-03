// File containing the main functions of the plugin (main loop and the function to refresh the leaderboard)

void RefreshLeaderboard(){
    auto startTime = Time::get_Now();
    int lastPbTime = currentPbTime;
    //No need to make this a coroutine since it is needed before executing the rest of the refresh
    LeaderboardEntry@ pbTimeTmp = GetPersonalBestEntry();

    if(pbTimeTmp.time == lastPbTime) {
        counterTries++;
        if(counterTries > maxTries) {
            print("Failed to refresh the leaderboard " + maxTries + " times, stopping the refresh. Time spent : " + (Time::get_Now() - startTime) + "ms");
            failedRefresh = true;
        }
        // we still want to try and get the other times
        if(counterTries > 1) {
            print("Failed to refresh the leaderboard " + counterTries + " times. Time spent : " + (Time::get_Now() - startTime) + "ms");
            return;
        }
        
    } else {
        counterTries = 0;
    }

    leaderboardArrayTmp = array<LeaderboardEntry@>();
    leaderboardArrayTmp.InsertLast(pbTimeTmp);

    // if activated, call the extra leaderboardAPI
    if(ExtraLeaderboardAPI::Active && useExternalAPI){
        ExtraLeaderboardAPI::ExtraLeaderboardAPIRequest@ req = ExtraLeaderboardAPI::PrepareRequest(true, true);

        ExtraLeaderboardAPI::ExtraLeaderboardAPIResponse@ resp = ExtraLeaderboardAPI::GetExtraLeaderboard(req);

        // We extract the times from the response if there's any
        if(resp is null){
            warn("response from ExtraLeaderboardAPI is null or empty");
            return;
        }

        // extract the medal entries
        array<LeaderboardEntry@> medalEntries;
        for(uint i = 0; i< resp.positions.Length; i++){
            if(resp.positions[i].entryType != EnumLeaderboardEntryType::MEDAL){
                continue;
            }
            medalEntries.InsertLast(resp.positions[i]);
        }
        // sort the medal entries then add the description to them
        medalEntries.SortAsc();

        array<string> medalDesc = {};
        // only add the medal description if the associated medal is activated
        if(showAT){
            medalDesc.InsertLast("AT");
        }
        if(showGold){
            medalDesc.InsertLast("Gold");
        }
        if(showSilver){
            medalDesc.InsertLast("Silver");
        }
        if(showBronze){
            medalDesc.InsertLast("Bronze");
        }

        for(uint i = 0; i< medalEntries.Length; i++){
            medalEntries[i].desc = medalDesc[i];
        }


        // Insert all entries in our temporary entry array
        for(uint i = 0; i< resp.positions.Length; i++){
            if(resp.positions[i].time == -1){
                continue;
            }
#if DEPENDENCY_CHAMPIONMEDALS
            // For now, we assume that if the entry type is TIME, it's the Champion medal, since we're only requesting this in the score list
            if(resp.positions[i].entryType == EnumLeaderboardEntryType::TIME){
                resp.positions[i].entryType = EnumLeaderboardEntryType::MEDAL;
                resp.positions[i].desc = "Champion";
            }
#endif
            leaderboardArrayTmp.InsertLast(resp.positions[i]);
        }
    } else {    
        // Make all the request in local (apart from impossible calls like medals above pb)
        array<Meta::PluginCoroutine@> coroutines;
        for(uint i = 0; i< allPositionToGet.Length; i++){
            auto timeEntryFunc = startnew(SpecificTimeEntryCoroutine, Integer(allPositionToGet[i]));
            coroutines.InsertLast(timeEntryFunc);
        }
        auto medalEntryFunc = startnew(AddMedalsEntriesCoroutine);
        coroutines.InsertLast(medalEntryFunc);

        await(coroutines);
    }

    // Time difference entry finding
    if(currentComboChoice == -1){
        // timeDifferenceEntry is the entry that has entryType Pb
        for(uint i = 0; i< leaderboardArrayTmp.Length; i++){
            if(leaderboardArrayTmp[i].entryType == EnumLeaderboardEntryType::PB){
                timeDifferenceEntry = leaderboardArrayTmp[i];
                break;
            }
        }
    }else{
        timeDifferenceEntry.time = -1;
        timeDifferenceEntry.position = -1;
        timeDifferenceEntry.entryType = EnumLeaderboardEntryType::POSITION; // Doesn't really matter since it isn't checked
        for(uint i = 1; i< leaderboardArrayTmp.Length; i++){
            if(leaderboardArrayTmp[i].position == currentComboChoice){
                timeDifferenceEntry = leaderboardArrayTmp[i];
                break;
            }
        }
    }

    //sort the array
    leaderboardArrayTmp.SortAsc();
    leaderboardArray = leaderboardArrayTmp;
    print("Refreshed the leaderboard in " + (Time::get_Now() - startTime) + "ms");
}


/**
 * Hack class to be able to have handles
 */
class Integer{
    int value;
    Integer(int value){
        this.value = value;
    }
}
void SpecificTimeEntryCoroutine(ref@ position){
    // cast ref to Integer
    Integer@ positionInt = cast<Integer@>(position);
    LeaderboardEntry@ timeEntry = GetSpecificTimeEntry(positionInt.value);
    if(timeEntry !is null && timeEntry.isValid()){
        leaderboardArrayTmp.InsertLast(timeEntry);
    }
}

void AddMedalsEntriesCoroutine(){
    array<LeaderboardEntry@> entries = GetMedalsEntries();
    for(uint i = 0; i< entries.Length; i++){
        if(entries[i] !is null && entries[i].isValid()){
            leaderboardArrayTmp.InsertLast(entries[i]);
        }
    }
}

void SpecificPositionEntryCoroutine(ref@ time){
    // cast ref to Integer
    Integer@ timeInt = cast<Integer@>(time);
    LeaderboardEntry@ positionEntry = GetSpecificPositionEntry(timeInt.value);
    if(positionEntry !is null && positionEntry.isValid()){
        leaderboardArrayTmp.InsertLast(positionEntry);
    }
}