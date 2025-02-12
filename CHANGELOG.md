## v.9.4.0
###### 12 Feb 2025

- General:
  - Added b42 Moodle Framework to requirements. It's only required for b42. They also share same modID, so I'm not even sure if it matters which one you use, b41 or b42 version.
  - Added ETWExportedFunctions.lua for modders to use, it has example inside, it's in shared folder. Currently, it supports progressing ETW Smoking system as requested by one of the modders. If you are a modder, and want to cook something up, msg me on Discord.
- Balancing:
  - Changed a bit Fear of Locations calculations, it's slightly easier to manage it now.
  - I am looking to balance the initial sandbox values to be good for plug-and-play. If you have suggestions regarding initial sandbox values please let me know.
  - Reminder that defaults changes do not apply to existing saves, use mods to change them, if you want
- Fixes:
  - Smoking system wasn't doing anything when smoking Cigarillo, Cigar and Smoking Tobacco. Now it works.
- Translations:
  - Added UA translation thanks to [Art Tippet](https://steamcommunity.com/profiles/76561198282198370)

## v.9.3.1
###### 29 Jan 2025

- Fixes:
  - Fixed not being able to get Wilderness Knowledge (and related error)
- Mod Conflicts:
  - Possible fix for occasional error when running NPC mods
- Translations:
  - IT translation update

## v.8.5.6 - for b41 version of the mod
###### 29 Jan 2025

- Fixes:
  - Fixed recipes not being unlocked

## v.8.5.5 - for b41 version of the mod
###### 28 Jan 2025

- Fixes:
  - Fixed broken exp boost gain

## v.9.3.0
###### 27 Jan 2025

- General:
  - Changed trait sound from a single selection to multi-selection, it's going to be random from selected if selected more than 1
- Fixes:
  - Fixed bug added in v.9.2.0 with player not geting ANY exp boosts when earning traits (ups)
  - Fixed moodles not showing
- Translations:
  - I am looking for PTBR language maintainer, my current one vanished without a trace??? If maintainer not found, translation will be removed in few updates.
  - Other languages maintainers are also always welcome. Please join Discord if you're interested.

## v.9.2.1
###### 24 Jan 2025

- General:
  - Changed all audio from .wav to .ogg which cuts the size of sounds from 11 MB to 800 kB
- Fixes:
  - Fixed submod not showing up in mod list


## v.9.2.0 - Sounds Fiesta
###### 24 Jan 2025

- General:
  - Added a trait sound selection, can be changed from mod options, have fun
  - Traits that add recipes are no longer hardcoded and instead fetch list of recipes directly from the trait so now when earning trait with recipes it's always going to be up-to-date, so if any mod or game update changes recipes it's going to be accounted for.
  - Traits that apply XP boost are no longer hardcoded either, now list of exp boosts is fetched from the trait itself so it's always up-do-date too.
  - Guess what, list of herbs for Herbalist is also not hardcoded anymore. So if mods adds new herbs that are Medical Herbs or Wild Herbs or Wild Plants, they will be accounted for. Same goes for game updates.
  - Losing a trait that unlocks recipes now locks them back until you acquire the trait again
  - Added support for new traits added in b42: Whittler, Blacksmith Knowledge, Wilderness Knowledge
  - Added proper changelog
  - A bit of internal code refactoring. I think I didn't break anything, but I'm not sure
- Balancing:
  - Bravery System default kills value is lowered (20k -> 14k)
  - Home Cook trait price lowered from 3 to 2
- Fixes:
  - Fixed Bravery System incorrect behaviour with a very specific set of conditions
  - Fixed Bravery part of UI displaying incorrect tooltip on 2 of its elements
  - Fixed sandbox value display for one of the settings

## v.8.5.4 - for b41 version of the mod
###### 24 Jan 2025
- Fixes:
  - Fixed Bravery System incorrect behaviour with a very specific set of conditions
  - Fixed Bravery part of UI displaying incorrect tooltip on 2 of its elements

## v.9.1.0
###### 06 Jan 2025
- General:
  - Kenshi and Sojutsu Martial Artist traits were removed as they were not fitting Zomboid setting
  - Added Blade Enthusiast trait to fill the place of Kenshi
  - Added Polearm Specialist trait to fill the place of Sojutsu Martial Artist
  - Added new trait Pet Therapy which gives mood boost when petting animals and gives +1 Husbandry
  - Removed dubug option from mod options since its no longer needed after UI was added. All debug outprints are not in detailed debug option.
- Fixes:
  - Fixed Herbalist not abiding by Traits Lock System
  - Fixed Immunity Bar not showing up in UI
  - Fixed ETW modData staying after character died so when creating new character after death without leaving to main menu first would keep old modData
  - Updated Herbalist to track new herbs added in b42
- Mod Conflicts:
  - Added Dynamic Traits and Expanded Moodles to incompatibilities, now that game supports it (finally no more questions "why am I getting spammed with weight traits?" from people incapable of reading incompatibilities list)
- Translations:
  - RU translation was removed. It was done by machine (which is fine by me as long as it's at least checked after by a human and fixed errors, which it wasn't) and was heavily outdated. The way most of the things where phrased in translation was terrible and very clearly not checked. Around only 40% of translation was usable. If someone wants to provide an actual translation, let me know on discord.

## v.8.5.3 - for b41 version of the mod
###### 06 Jan 2025
- Fixes:
  - Fixed Herbalist not abiding by Traits Lock System
  - Fixed Immunity Bar not showing up in UI
  - Fixed ETW modData staying after character died so when creating new character after death without leaving to main menu first would keep old modData

## v.9.0.1
###### 24 Dec 2024
- Fixes:
  - Fixed all repairing-related code. Means now repairing cars gives progress to earning traits that require it. Also means Restoration Expert is actually working now.
  - Fixed submod breaking auto-sort in mod menu.
- Translations:
  - Fixed old translation files for b42 (also you should use english while b42 is unstable, I will not be asking translators to update translatons until b42 is out)

## v.9.0.0 - B42 update
###### 22 Dec 2024
- General:
  - Compatibility update for b42
  - Mod options are no longer needed for b42, same for TchernoLib

## v.8.5.2
###### 08 Oct 2024
- Fixes:
  - Fixed error in ETWCommonLogicChecks.lua
  - Fixed a harmless warn on server requiring "ETWModData"
- Translations:
  - DE, CN, CH translations updates

## v.8.5.1
###### 17 Sep 2024
- Fixes:
  - Fixed error in food sickness function (ETWByHealth.lua line # 59)
- Translations:
  - KO update

## v.8.5.0
###### 16 Sep 2024
- General:
  - Reworked Cold Illness System into Immune System, now it's just a counter that you increase by having cold. Additionally, having Knox infection also contributes to it now. So running  mods that let you fight infection (for example, Antibodies) can help with this
  - Added Outdoorsman counter increase multiplier which was missing from sandbox, now added
  - Outdoorsman System and Fear of Locations System now get progress when killing stuff (read sandbox description for more details)
  - Normal sickness now contributes to Food Sickness System. Sandbox options are present, default contribution multiplier is 25%
- Balancing:
  - Reduced default Herbalist counter and decay (1000 -> 250 and 1 -> 0.2)
  - Reduced default Axeman counter (500 -> 250)
  - Reminder that defaults changes do not apply to existing saves, use mods to change them, if you want

## v.8.4.1
###### 15 Sep 2024
- Fixes:
  - Fixed harmless error on server launch
  - Fixed Rain counter behaving weirdly sometimes.
- Translations:
  - KO, CN, CH translations update

## v.8.4.0
###### 10 Sep 2024
- General:
  - Refactored weather functions a bit
  - Making kills while in the rain or in the fog now gives progress to Fog System and Rain System traits
  - Moved a bunch of stuff around, looks like everything is still working
- Balancing:
  - Lowered defaults for Item Transfer System
  - Slightly adjusted the distance at which you get maximum Bloodlust meter fill
- Fixes:
  - Fixed Bloodlust system being reset to 0 if player wears no clothes
  - (Possible) Fix on some client-side code being run on server in MP and throwing errors every now in then in server console.
  - Fixed Sewer/Tailor trait check not being triggered on ripping enough clothes.
- Mod Conflicts:
  - When moving items with negative weight (for example, mod items used to artificially increase size of containers) it no longer reduces your Item Weight Moved progress in Inventory Transfer System

## v.8.3.1
###### 08 Sep 2024
- Fixes:
  - Fixed UI breaking on first character load

## v.8.3.0
###### 08 Sep 2024
- General:
  - Sewer now also requires you to rip unique clothing. Probably compatible with modded clothes (tested with AuthenticZ and Britas Armor Pack)
  - Added a Readme in UI to save people trouble of asking for things that are already in the mod.

## v.8.2.2
###### 07 Sep 2024
- Fixes:
  - Fixed Bloodlust bar on UI having labels in incorrect position
- Mod Conflicts:
  - Fixed error when zombie killed by someone else than a player (like NPC from Bandits mod)
- Translations:
  - KO update, looking for more maintainers of existing languages, they are lagging behind a bit. Ping me on discord if someone wants to help.

## v.8.2.1
###### 05 Sep 2024
- Fixes:
  - Fixed repeated Tailor notifications

## v.8.2.0
###### 05 Sep 2024
- General:
  - Bloodlust Meter (one you fill by killing stuff) is now capped at 300%. Adjustable in Sandbox
  - Kills made at night now help with earning Cat Eyes
  - Having Eagle Eyed doubles gain rate of Cat Eyes
  - Added new Rain System sandbox setting
  - Adjusted default settings for Rain System and Fog System
- Fixes:
  - Fixed doubled notification when gaining traits through Delay Traits System
  - Fixed Bloodlust Meter not decaying
- Translations:
  - Fixed all encodings, should be no more weird symbols.

## v.8.1.1
###### 03 Sep 2024
- Fixes:
  - Fixed Bravery System not working (ups)
- Translations:
  - I hate encodings. Fixed RU

## v.8.1.0
###### 03 Sep 2024
- General:
  - Some Bloodlust balancing, it's slightly harder to fill the meter
  - Added sound notification when getting/losing trait or adding it to Delayed Traits System. Toggable in Mod Options.
  - Now engine repairs are counted towards Vehicle Repair counter. Special shout-out to Albion for big help with figuring server-client communication.
- Fixes:
  - Fixed Desensitized being unobtainable
- Translations:
  - KO translation got some polishing

## v.8.0.4
###### 02 Sep 2024
- General:
  - A bit of internal micro-optimizations
- Fixes:
  - Fixed Knife Fighter in UI having wrong tooltip
- Translations:
  - KO translation update thanks to new maintainer, KimLeon

## v.8.0.2
###### 31 Aug 2024
- Fixes:
    - Fixed error thrown when detailed debug enabled in mod options

## v.8.0.1
###### 31 Aug 2024
- Fixes:
  - Knife Fighter minor fix
  - Refined function that checks how bloodied player is, now it's accurate and doesn't include items that can't be bloodied in calculation.

## v.8.0.0 - Proper Types and Classes
###### 30 Aug 2024
- General:
  - Huge internal refactor and documentation work, mostly just coding stuff and making project work better with IDE. Non-relevant to average player, unless I broke stuff.
  - Bloodlust gain/lose is now affected by general level of your bloodied clothes. Has only positive net gain. Having no bloodied clothes doesn't change speed of getting/losing the trait. Having bloodied clothes makes it easier to get the trait and harder to lose it.
  - Made Bloodlust softcap less harsh (you can go above 100% meter fill easier)
  - Bravery system now will not allow you to earn next trait in progression until previous trait is gone (if it's negative) or present (if it's positive)
  - Added ModOption to disable Smoker bar display in UI
- Fixes:
  - Cold System had a bug when Delayed Traits System was enabled
  - Fixed some traits being dynamic when they shouldn't be and vice versa

## v.7.2.0
###### 25 Aug 2024
- General:
  - Added hotkey to toggle new UI. It can be found in Options -> Key Bindings -> UI, default is "[" (left bracket, button next to P)

## v.7.1.3
###### 05 Aug 2024
- Fixes:
  - Fixed Bloodlust, Asthmatic and Outdoorsman not abiding by Trait Lock system

## v.7.1.2
###### 31 Jul 2024
- Fixes:
  - Fixed repeated Eagle-Eyed notifications
- Translations:
  - Added German translation thanks to [Lampiooo](https://steamcommunity.com/profiles/76561198147574632)

## v.7.1.1
###### 16 Jul 2024
- Fixes:
  - Fixed edge case where UI could break dues to edge-case in rendering Inventory Transfer system progress
- Translations:
  - PTBR translation got some love

## v.7.1.0
###### 14 Jul 2024
- General:
  - Added tooltip for gradient bars, how it will display your current counter value when hovering over it.
  - Lowered default values for fog and rain systems so it's more reasonable without additional tweaking
- Translations:
  - Did some Quality Assurance on English lines, fixed various grammar mistakes and improved overall readability.

## v.7.0.4
###### 12 Jul 2024
- Fixes:
  - Fixed Slow Learner notifications popping up every level-up
  - Fixed not being able to lose Agoraphobic or Claustrophobic sometimes

## v.7.0.3
###### 06 Jul 2024
- Fixes:
  - Removed Smoker Moodle from Sandbox
  - Fixed Smoker Bar showing incorrect info
  - Fixed Pain Tolerance being unobtainable if it's in delayed traits system
- Translations:
  - PTBR translation update

## v.7.0.2
###### 05 Jul 2024
- Fixes:
  - Fixed delayed notifications not showing correct strings
  - Fixed Baseball player showing up non-stop

## v.7.0.1
###### 04 Jul 2024
- Fixes:
  - Fixed UI breaking (ETWCharacterPage.lua line # 406), there might be more errors, I'll need logs to fix it. Send them on Discord. Or in the thread.

## v.7.0.0 - UI Rollout
###### 04 Jul 2024
- General:
  - This is the biggest update I've done yet: UI is here. It has everything you need to know. There are also tooltips. And mod settings. And sandbox settings. Almost 2000 new lines of code. This almost doubled mod size code-wise.
  - Large refactor of conditions for increasing maintainability and reusability of the code, should be less error-prone now
  - Asthmatic System was written in a dumb way, I rewrote it so expect to suddenly gain/loose Asthmatic when loading into pre-version 7.0.0 saves. Sorry. You can fix in debug mode by pasting this in console: "getPlayer()player:getModData().EvolvingTraitsWorld.AsthmaticCounter = -getPlayer()player:getModData().EvolvingTraitsWorld.AsthmaticCounter", without the quote marks.
  - Smoker counter also wasn't making a lot of sense, so I had to change it too. Internally it was able to go between 0 and sandbox value multiplied by 2. For coding and consistency purposes I have to change it to go between minus sandbox x2 and sandbox x2. Shouldn't really change much but may take longer to gain/lose smoker now.
  - Following above change, adjusted default Smoker Addiction Decay Multiplier from 8 to 12. Would recommend adjusting it on existent games
  - Outdoorsman had similar but slightly different issue, so things got slightly re-arranged there too. Nothing as drastic as Asthmatic but some of you might lose/gain it too. Not fixable in debug mode like Asthmatic is.
  - Fast/Slow Learner merged into a system instead of being 2 separate thing
  - New dependency to add UI page, TchernoLib
- Moodles:
  - Removed Smoker Moodle, now this information can be found on UI character page.
- Fixes:
  - Possible fix on error popping up after dying and making new character
  - Fixed bravery system showing incorrect notification when losing Cowardly
  - Fixed Asthmatic sandbox description
  - Fixed Outdoorsman and Asthmatic sometimes not being locked by Traits Lock System
  - Fixed some logic mistakes that appeared in last update
- Translations:
  - Mostly up to date, need maintainers for KO, PTBR and RU

## v.6.0.0 - Traits Lock Rollout
###### 17 Jun 2024
- General:
  - Added trait lock system which affect every single perk, can be found in systems page. Allows you to restrict if positive/negative perks can be gained/lost. Applies globally, so instead of going and figuring out what sandbox settings to change, so you can't lose positive perks or can't gain negative you can just change these sandbox settings.
- Fixes:
  - Few being unable to gain Inconspicuous
  - Removed some redundant and not working safeguard in Sleep System.


## v.5.4.2
###### 14 Apr 2024
- Fixes:
  - Changed some default smoker values a bit to be more realistic
- Translations:
  - Added Turkish translation thanks to [MUTANT_Hero](https://steamcommunity.com/profiles/76561199237578839)

## v.5.4.1
###### 10 Mar 2024
- Mod Conflicts:
  - Added compatibility for zRe ARMOR PACK by [kERHUS](https://steamcommunity.com/workshop/filedetails/?id=3038026478)
- Translations:
  - Updated translations

## v.5.4.0
###### 22 Feb 2024
- General:
  - Added sandbox option to make Agoraphobic and Claustrophobic exclusive, so you will only ever have 1 at the time. Enabled by default.
  - Changed default value of "Debug" in Mod Options to false
- Fixes:
  - Fixed sandbox string not being displayed for one of Fear Of Locations option

## v.5.3.4
###### 08 Dec 2023
- Fixes:
  - Fixed error thrown by recordMentalState when dying

## v.5.3.3
###### 07 Dec 2023
- Translations:
  - New translation: Korean (KO), thanks to t3qquq
  - Some CN translation improvements
  - Update ES translation to 5.3.3 thanks to new ES maintainer Get

## v.5.3.2
###### 02 Dec 2023
- Fixes:
  - Fixed vehicle repairs not being counted in MP, additionally repairing anything that gives vehicle exp now counts towards earning related perks. Thanks to JS.
- Translations:
  - Updated IT translation

## v.5.3.1
###### 30 Nov 2023
- Fixes:
  - Fixed Knife Fighter not increasing exp multiplier when earned
- Translations:
  - Updated CN and CH translations
  - Still looking for more maintainers of existing languages and new translators for missing ones

## v.5.3.0
###### 29 Nov 2023
- General:
  - Added Pain Tolerance trait.
  - Adjusted AV Club perk cost 5 -> 4
  - Moved general settings (Affinity and Delay systems) to its own sandbox page where stuff that affects major parts of mod can be found
  - Added option for Fear of Locations system to slowly decay by itself for all of you with skill issues complaining about having both Agoraphobic and Claustrophobic after picking up every possible negative perk in existence for 'free points'. Not tested but should work.

## v.5.2.5
###### 22 Nov 2023
- Fixes:
    - Fixed duplicating perks during character creation
    - Submod was incorrectly showing Nutritionist as dynamic when running SOTO

## v.5.2.4
###### 23 Oct 2023
- Fixes:
  - Fixed Pluviophobia Multiplier sandbox setting using incorrect translation string.
- Mod Conflicts:
  - Rewrote code responsible for carry weight calculations when using Alice Packs

## v.5.2.3
###### 11 Oct 2023
- Fixes:
  - You could have been gaining smoking addiction instead of losing/keeping it stable when you don't smoke due to how game handles stress, now the worst case scenario is that you don't gain/lose any progress
- Translations:
  - Updated PTBR translation to latest mod version

## v.5.2.2
###### 04 Oct 2023
- Fixes:
    - Fixed repeated "Qualified for Eagle Eyed" notification.

## v.5.2.1
###### 03 Oct 2023
- Fixes:
  - Fixed constantly gaining/losing some of the weight system traits.

## v.5.2.0
###### 02 Oct 2023
- General:
  - Weight System now uses your mental state over course of last 31 days instead of current mental state, details in sandbox/google sheets. Should work. Not tested. Good luck.

## v.5.1.6
###### 28 Sep 2023
- Mod Conflicts:
  - Slight code optimizations for carry weight calculations (was running SOTO compatibility code when SOTO wasn't even enabled)
  - Possible fix for errors caused by bloodlust code being ran when kill is made by NPC

## v.5.1.5
###### 27 Sep 2023
- Fixes:
    - Fixed smoking not being detected for purposes of losing smoker trait in singleplayer (oups)

## v.5.1.4
###### 03 Sep 2023
- Fixes:
    - Fixed repeated "qualified for xyz" msgs, now it will pop up only once (as intended)
    - Fixed Lucky/Unlucky acquisition (was checking wrong stuff)
    - Added missing popups for when qualifying for some traits (some traits weren't informing that you are qualified for them)

## v.5.1.3
###### 01 Sep 2023
- Fixes:
    - Added some safeguards (where they were missing) for character stats (panic, boredom, etc.) to not go above/below game limits

## v.5.1.2
###### 19 Jul 2023
- Fixes:
  - Fixed some traits exclusivity

## v.5.1.1
###### 25 Jun 2023
- Translations:
  - RU, ES and IT translations update. Now all should be up-to-date, if you notice some bad/missing translations feel free to hop in discord and mention it in #translations channel.

## v.5.1.0
###### 16 Jun 2023
- General:
  - Added Mod Options setting to show pop-ups when you qualify for gaining/losing traits with Delayed System enabled.
  - Optimized code here and there
  - Added additional detailed debug printouts to sleep system
- Fixes:
  - Lucky/Unlucky added to Delayed Traits system (missed it on initial 5.0.0 release, ups)
  - Fixed Hunter popup triggering every kill after you qualify for it
  - Sleep System was broken, your Last Sleep Midpoint was always set to 4am

## v.5.0.3
###### 12 Jun 2023
- Fixes:
    - Fixed item transfer stuff (incorrect moddata table)

## v.5.0.2
###### 12 Jun 2023
- Fixes:
  - Fixed ISInventoryTransferAction:perform() passing wrong modData to Delayed Traits system functions
- Translations:
  - Added Português Brasileiro / Brazilian Portuguese translation, thanks to [Colossus_ND](https://steamcommunity.com/profiles/76561198154549234)
  - Updated CN and CH translations to current version
  - Only translation that is outdated is Russian, if someone can help with maintaining it, it would be nice.

## v.5.0.1
###### 07 Jun 2023
- Fixes:
  - Fixed error when trying to smoke.

## v.5.0.0 - Delayed Traits Overhaul
###### 07 Jun 2023
- General:
  - Delayed Traits System: From now on, by default, the majority of traits are subject to Delayed Traits System (can be disabled in Systems). With it enabled, when you qualify for new trait, it's added into a table that holds all the traits you qualify for, along with number of hours it CAN take for trait to appear/disappear. Every hour, game is rolling random number between 0 and max hours. If it lands on 0, you get the trait, and it's removed from table. If it doesn't, max hours goes down by 1 hour. So if sandbox is set to 336h (14 days) and you qualify for a trait, it will get added to table, and from now on every hour it'll roll to see if you get it. 1st roll chance is 1 in 336, 2nd roll is 1 in 335, and so on. So it adds a bit of randomness in traits acquisition. For more details read info in new sandbox options (Evolving Traits World - Systems). This only affects traits that can be only gained or only lost. For traits that can be both gained and lost it doesn't apply, and they are gained/lost instantly as before.
  - Bloodlust, Fog, Rain traits optimization.
  - Bloodlust effect now has sandbox setting to adjust how much it reduced unhappiness/stress/panic.
  - Split debug into two options, old one still will print all the counters in console.txt, new one will print additional information that only useful for bug reports. Usually you don't want to have it enabled. By default, it's disabled.
  - Sleep System is now synced with vanilla "SleepNeeded" server setting. If SleepNeeded is disabled, everything related to SleepSystem is automatically disabled.
  - Tidied-up and categorized console printouts, additionally added few more printouts in some old code where it's missing and might be useful.
  - Minor code optimizations.
  - Google sheet now has all new traits descriptions.
- Fixes:
  - Rain and Fog traits logic was disabled, so they were doing nothing (huh?).
  - Fixed incorrect smoker addiction counter calculations (if you were panicked/stressed, you were losing smoker faster instead of losing it slower)
- Mod Conflicts:
  - Should be now compatible with all versions of Superb Survivors or whatever other mod that adds NPCs.
- Translations:
  - Looking for someone to help to maintain RU translation.
  - Looking for translators for other languages.

## v.4.3.8
###### 04 Jun 2023
- Fixes:
    - Slow/Fast learner were missing Cooking from unlock calculations

## v.4.3.7
###### 19 May 2023
- General:
  - Added console prints for ISFixAction:perform(), so now you can check console to see if my scripts pick up you repairing items/cars.
- Translations:
  - Somehow lost CN and CH translation files, added them back.

## v.4.3.6
###### 11 May 2023
- Fixes:
    - Fixed kills calculation for Bravery system (was counting firearm kills twice)

## v.4.3.5
###### 30 Apr 2023
- Fixes:
    - Replaced all onCharacterDeath with onPlayerDeath (this was clearing all mod events/logic when ANY character dies, instead of doing it when player dies), everything should be working now.

## v.4.3.4
###### 30 Apr 2023
- Fixes:
    - Fixed carry weight being weird when both More Traits, SOTO and ETW carry weight perks are present.

## v.4.3.2
###### 29 Apr 2023
- Fixes:
  - Follow-up fix for error after creating new character in same world after old one dies (missed 1 file)
  - Fixed carry weight being weird when both SOTO and ETW carry weight perks are present.
- Translations:
  - Added Chinese and Traditional Chinese thanks to [NEP IS LIFE](https://steamcommunity.com/profiles/76561198164560009)

## v.4.3.1
###### 28 Apr 2023
- Fixes:
    - Fixed error after creating new character in same world after old one dies.

## v.4.3.0
###### 18 Apr 2023
- General:
  - New sandbox option that removes all fear traits when you gain Desensitized (Default - off)
- Fixes:
  - Fixed melee kills only count once for Bravery system, instead of twice as intended.

## v.4.2.0_blaze_it
###### 23 Mar 2023
- General:
  - Restoration Expert now has % setting to trigger. [1-100]. Default is 75%. Make sure to change it, if you want it to be 100% (or anything else).
  - Added Axeman, Burglar and Graceful.
- Fixes:
  - "Hunter Skill level" sandbox option adjusted to have minimum value of 8.

## v.4.1.5
###### 14 Mar 2023
- Translations:
  - Added Spanish translation, thanks to [Akillez](https://steamcommunity.com/profiles/76561198331608167)
  - Fixed incorrect line in RU and IT translations for Hoarder perk.

## v.4.1.4
###### 11 Mar 2023
- Translations:
  - Added Russian translation, thanks to [Machine Intelligence](https://steamcommunity.com/profiles/76561198066675134)

## v.4.1.3
###### 01 Mar 2023
- Fixes:
  - Fix for error that is thrown on server-side when someone tries to smoke. Credits to [Burryaga](https://steamcommunity.com/profiles/76561198276941338)

## v.4.1.2
###### 21 Feb 2023
- General:
  - Adjusted smoker default values, so it's faster to lose smoker. "Smoking Addiction Decay Multiplier" Default value 1 -> 8, Max value 100 -> 1000.
- Fixes:
  - Fixed Smoker leaving stress from cigarettes on your character upon losing the trait
  - Removed Graceful from submod marking it dynamic while it's not (I'll make it dynamic, just a bit later). It still will be marked with D if you have SOTO running, 'cuz SOTO makes it dynamic too.

## v.4.1.1
###### 18 Feb 2023
- Fixes:
  - Fixed Low Profile using Axe skill as requirement instead of Sneaking

## v.4.1.0
###### 17 Feb 2023
- General:
  - You can now disable perks you don't like completely with the help of this mod: [Evolving Traits World (ETW) - Disable Selected Traits](https://steamcommunity.com/sharedfiles/filedetails/?edit=true&id=2934686936) (should be helpful for server admins who like the mod but want to disable a perk or two)
- Fixes:
  - Fixed Mechanic skill stuff.
  - Removed some un-needed code.

## v.4.0.2
###### 03 Feb 2023
- Fixes:
  - Fixed error in ETWFunctionsOverride.lua trying to access incorrect value in table.

## v.4.0.1
###### 03 Feb 2023
- Fixes:
  - Fixed error in ETWByTime.lua trying to access incorrect value in table.

## v.4.0.0 - Affinity System Rollout
###### 03 Feb 2023
- General:
  - Added Affinity System - Affects some traits tied to systems and some complex ones (for example, weight Fear of Locations system, Herbalist, or Sleep System. Check which Systems and Traits are a subject to Affinity system in Google sheets). Affinity system makes it easier to hold onto traits you picked on character creation, both negative and positive. With it enabled, you halve (modifiable) the speed at which you lose these traits, and double (also modifiable) the speed at which you earn these traits.
  - Asthmatic is no longer permanent at if picked at character creation, now it's meant to be used with Affinity System enabled.
- Fixes:
  - Due to some Stress calculations on game side, all my stress adding/removing was broken if player had Smoker trait. Now it's fixed. Includes Bloodlust, Pluviophobia / Pluviophile, Homichlophile / Homichlophobia
- Translations:
  - Updated ITA to 4.0.0

## v.3.0.2
###### 27 Jan 2023
- Fixes:
  - Fixed Asthmatic not increasing counter if you have smoker and run in 10+ degrees. Now it does, as intended.
  - Fixed Asthmatic counter values being able to go outside intended boundaries.
  - Starting with Bloodlust will now set your Bloodlust Meter to 50% (Bloodlust Progress id different thing and still set at 100% if you start with it).
  - Fixed FearOfOutside counter not changing unless players had debug enabled (oups).
  - Some code polishing.

## v.3.0.1
###### 20 Jan 2023
- Fixes:
  - Fixed fog traits trying to use non-existing sandbox variables. Check "Traits" sandbox page to see 2 new sandbox vars.

## v.3.0.0 - Sandbox and Debug polishing
###### 18 Jan 2023
- General:
  - Added ModOptions option to printout debug information to console.txt, this is going to help with fixing stuff, additionally you can see there all internal counters. Ctrl+F for "ETW" to find all the loggers.
  - Sandbox pages got a bit of restructuring. Everything that requires just some skill levels and maybe additional thing or two now can be found on "Simple Perks" page, more complex stuff like Smoker or Herbalist or Cat Eyes is now on "Complex Perks" page.
  - Sandbox options added for Herbalist decay rate.
  - Code optimization for Cat Eyes, Pluviophile, Pluviophobia, Outdoorsman
  - New traits: Homichlophile, Homichlophobia - love and fear of fog. Dynamic options are present in sandbox, as always.
  - Fear of Locations system math change, now there's no jump from 0 to 1 as soon as you got even a bit of stress or unhappiness.
  - Rain Traits math change, now it's more consistent with the rest of the systems.
- Fixes:
  - Clumsy was connected to incorrect sandbox option.
- Translations:
  - Updated ITA to 3.0.0

## v.2.1.7
###### 16 Jan 2023
- Fixes:
  - Sleep System math fix (didn't go through last patch)

## v.2.1.6
###### 16 Jan 2023
- Moodles:
    - New Bloodlust trait/moodle icon (courtesy of [Olipro](https://steamcommunity.com/profiles/76561198027445715))
  - Bloodlust moodle description clarification
- Fixes:
  - Sleep System math fix
  - Bloodlust math fix (perk is now better)

## v.2.1.5
###### 16 Jan 2023
- Mod Conflicts:
  - Fixed Superb Survivors incompatibility (item transfer was bugged for NPCs).

## v.2.1.4
###### 15 Jan 2023
- Fixes:
    - Fixed Fear of Location traits math.

## v.2.1.3
###### 14 Jan 2023
- Fixes:
    - Fixed Herbalist being added multiple times
- Translations:
    - ITA translation files polishing

## v.2.1.2
###### 14 Jan 2023
- Fixes:
    - Fix on Claustrophobic and Agoraphobic moddata initialization.
    - Fix on Pluviophobia and Pluviophile moddata initialization.
    - Fix Sewer being dependent on Mechanics instead of Tailoring.
    - Fix on Angler tooltip

## v.2.1.1
###### 13 Jan 2023
- Fixes:
  - Fixed Smoker moodle being displayed when shouldn't
  - Updated Submod with missing traits, added new notation, (P/D) means that they are permanent if picked in character creation, but if not picked they are dynamic and obtainable/losable during the game.

## v.2.1.0
###### 13 Jan 2023
- General:
  - Herbalist can be lost now, counter very slowly decays (1/day).
  - Slightly buffed Bloodlust, now also removes some stress and panic when killing zombies
- Fixes:
  - Fixed Outdoorsman being removed upon starting with it. Existing characters will have to manually earn it, new characters will behave as expected.
  - Found some issues here and there in code, fixed them.

## v.2.0.1
###### 13 Jan 2023
- Fixes:
  - SmokerMoodlePercentage sandbox was linked to incorrect localization string.
  - Fixed smoker being auto-removed when player start with it. Can't help existing characters on my side, but new ones will behave properly.
- Translations:
  - Changed Italian translation to correct encoding.

## v.2.0.0 - Negative Traits Rollout
###### 13 Jan 2023
- General:
  - Asked Star to fix Sandbox Options mod, now it's working, enjoy changing your sandbox settings after game start (link in description)
  - Claustrophobic and Agoraphobic can be gained now. Existing progress is lost due splitting system into 2 different parts. New Sandbox Options included.
  - Outdoorsman can be lost now. Existing progress is lost due to system being rebuilt. New Sandbox Options included.
  - Pluviophobia can be gained now, Pluviophile can be lost now. Existing progress is saved but can be a bit weird since system was rescaled from 0% - 200% to -100% - 200%. New Sandbox Options included.
  - Asthmatic can be gained and lost now. Be aware that if you pick it on character creation, it's permanent. Sandbox options included.
  - Changed Sleep system due to impossible logic problems, now it's much simpler, and it's much easier to shift your schedule. I liked old system, but it wasn't working as intended.
  - Smoker is added and can be lost and earned. Sandbox options included.
  - Added ModOption to enable/disable notifications whenever you get the trait.
- Moodles:
  - New sandbox options for Bloodlust and Sleep System moodles. Server admins can disable them for players by adjusting sandbox setting.
  - Smoker Moodle added. Shows how close you are from gaining or losing the trait. Sandbox options included.
- Fixes:
  - Fixed traits showing their description twice.
  - Fixed missing initialization for fresh characters, so they get starting traits if they qualify for them.
- Mod Conflicts:
  - Another shot at trying to resolve errors when ran with Superb Survivors.
  - Forage action shouldn't conflict with Snake modpack anymore.
- Translations:
  - Italian translation added, courtesy of UattO

## v.1.3.1
###### 10 Jan 2023
- Moodles:
    - Sleep Health moodle now shows precise hours to your optimal sleeping hour.
- Fixes:
  - Fixed Sleep Heath Moodle displaying incorrect information.

## v.1.3.0
###### 09 Jan 2023
- General:
    - Added support for Dynamic Traits to submod. Main mod is still not compatible and won't be. Reminder that submod can be run without running main mod.
- Mod Conflicts:
    - Resolved mod conflict with Superb Survivors!

## v.1.2.1
###### 08 Jan 2023
- Fixes:
  - Fixed Submod showing traits made dynamic by ETW even when ETW was not enabled (I forgor :c)

## v.1.2.0
###### 08 Jan 2023
- General:
    - Mark Dynamic Traits submod is using much smarter logic, utilizing existing translations and just adding "(D)" at the end of the trait name, instead of using manually written translation files.
    - Removed ETW dependency from submod, meaning you can run submod without running main file.
    - Added support for SOTO to submod.
- Moodles:
    - Added moodle for Sleep Schedule system, now you can see if you're sleeping in correct hours via the moodle, only active while sleeping.
    - Bloodlust Moodle is now shown only within 6 (customizable via sandbox) hours after killing a zombie
    - Bloodlust Moodle is now showing exact % how filled your Bloodlust Meter is.
    - New Sandbox Settings page, for moodle settings, at the moment it's quite empty, but new moodle settings will be there with time.

## v.1.1.3
###### 07 Jan 2023
- General:
    - Mod rebranding
- Fixes:
    - Small fix for weight system

## v.1.1.2
###### 04 Jan 2023
- Fixes
    - Made migration from DT to DTW painless
    - Few small fixes in weight system

## v.1.1.1
###### 04 Jan 2023
- Fixes
  - Fixed Pluviophile and Pluviophobia not being mutually exclusive
  - Fixed Wakeful and Sleepyhead using names of the opposite trait (they were working the same, it was only name mix-up)

## v.1.1.0 - Public Release
###### 04 Jan 2023

