﻿# Boundir's XCOM 2 Tweaks

## This mod is a collection of alterations to the game.


> ---
> #### It contains the following changes:
>
> - [Better Repeater](https://steamcommunity.com/sharedfiles/filedetails/?id=1130014360) by **derBK** with detailed description and bonus damage with Inside Knowledge.
> - Stasis removes Damage Over Time effects (fire, poison, chryssalid poison, acid, bleeding).
> - Bluescreen and [Null rounds](https://steamcommunity.com/sharedfiles/filedetails/?id=1959228411) by **AdmiralKirk** reworked to affect classes and specified units.
> - Disruptor rifle crit ability will affect Psionics units. Even the one used by the Chosen Warlock.
> - Horde sitrep won't appear after Force Level 8.
> - Dark Events can require specific conditions to appear. By default:
>   - *Loyalty Among Thieves* dark events requires their respective Chosen to be alive.
>   - *Undying Loyalty* & *Lost World* are disabled.
>   - *Made Whole* requires the Chosen to have at least one weakness.
>   - *Spider and Fly*, *Left Behind*, *Wild Hunt* require that all Chosen have not been killed.
> - Lock [Psionic class](https://steamcommunity.com/sharedfiles/filedetails/?id=1138411890) by **ADVENT Avenger** training in GTS after research is completed (default research is *Psionics*)
> - Covert Actions limits the amount of bonus stats on soldier can get. Covert Actions will not display the reward if the staffed unit has reached the limit.
> - *Rage Strike* is considered a melee attack.
> - Reduces environmental damages from weapons and abilities.
> - *Suppression* ability tweaks inspired by [Ability Tweaks](https://steamcommunity.com/sharedfiles/filedetails/?id=1133528728) by **ADVENT Avenger**:
>   - avoid usage against units with *Shadowstep*.
>   - *Teleport* removes *Suppression*.
>   - unavailable abilities while suppressed (*Suppression*, *Stealth*, *Vanish*, *SitRepStealth*, *Shadow*, *DistractionShadow*, *RefractionFieldAbility*)
> - [EU Berserker](https://steamcommunity.com/sharedfiles/filedetails/?id=1502891114) by **MrShadow** can only use react to being hit on XCOM turn. Its *Bullrush* ability can only trigger a *Devastating Punch* at melee range.
> - Ruler activation will pause timers. Ruler escaping or killed will resume it.
> - *Pounce* from [More Trait](https://steamcommunity.com/sharedfiles/filedetails/?id=1122837889) by **RealityMachina** is prevented from triggering while concealed.
> - Change *Axe Thrown* damage type to DefaultProjectile so it doesn't inflict melee damages.
> - Prevents Rulers from spawning on missions with Lost. Disabled by default since Lost cannot target Rulers and Chosen.
> - Covert Actions let you recruit Faction soldier indistinctively of which faction you first met. Limited to 2 of each by default.
> - Remove EasyToHit from civilian to help with retaliation mission with AI activated.
> - Training Center Ability Points restrictions. Psionic class is not able to purchase additional abilities.
> - Purchasing abilities through Training Center increases the cost exponentially except for Hero classes.
> - Replace loot from modded enemies to vanilla versions so we don't end up undesired items.
> - Chosen Assassin acquire a form of Bladestorm that can't miss. Can only trigger once per turn.
> - Resistance Warrior additional character is pulled from the pool.
> - Modify Weapon Breakthroughs condition to allow WeaponCat array.
> - Prevents listed abilities to also apply weapon damages.
> - Feedback resistance card triggers once per attack.
> - Militia won't target listed unit types.
> - Lost won't target listed unit types (Rulers & Chosen).
> - Chosen Dark Claw pierce some armor depending on weapon tier. Default values: pierce 2, 3, 4, 5.
> - Option to disable ambush and Guardian Angels resistance card. Off by default.
>
>> #### Plans:
>> - [x] Chosen action *Training* adds Strength and removes a number of weaknesses. *Require testing*.
>> - [x] Remove units from SpawnDistributionsLists programmatically to avoid mod config load order.
>> - [x] Manage loadout programmatically to avoid mod config load order.
>
> ---
