---
title: "NFSMW2012 : making opponents fly"
author: "Redouane"
date: 2018-01-20T00:00:00+02:00
description: "Getting cops and opponents to fly on Need for Speed most wanted 2012"
tags: ["gamehacking", "cheat engine", "reverse engineering", "assembly", "gaming"]
---
This is a gamehacking tutorial targeting ``Need for Speed Most Wanted 2012``.

[![Gameplay](/img/nfsmw2012_making_opponents_fly/gameplay.png)](/img/nfsmw2012_making_opponents_fly/gameplay.png)

In this tutorial, I will register a hotkey that when pressed, will raise all the opponents by ``20m`` to the sky (and by opponents I mean both cops and race opponents), lets start :D

We'll start by searching for the ``z`` coordinate of our car (a value that indicates its height), we must keep in mind that the ``z`` axis might be inverted (ie. when our height increases, ``z`` might increase or decrease)

- This value has two possible types : Float and Double (because it's a real number)

- There are two possible cases :
  - Getting more height increases ``z``
  - It decreases ``z``

So there will be a total of ``4`` cases, we can use different tabs to speed up the process, but we'll start with the most likely (Float type, because FPU arithmetic is faster on single floats, game programmers like to use it for coordinates and values that are involved in lots of calculations)
Each time, we will start by scanning for an unknown initial value (because we don't know the initial ``z`` value).
Lets start with float, increasing value when we get more height:

[![209,290,240 results](/img/nfsmw2012_making_opponents_fly/unknown_initial_value.png)](/img/nfsmw2012_making_opponents_fly/unknown_initial_value.png)

``209,290,240`` results, that's a lot! lets advance a little and rescan for decreased values, it will remove all the values that didn't decrease when we lost height.

[![2,516,010 results](/img/nfsmw2012_making_opponents_fly/next1.png)](/img/nfsmw2012_making_opponents_fly/next1.png)

``2,516,010`` results, ``99%`` of the first scan results are already filtered out, let's keep filtering, let's get back up, and rescan for increased value, then rescan for unchanged values without moving (the ``z`` value shouldn't change if we stand in-place, we will rescan for unchanged while the game is paused)

[![584,104 results](/img/nfsmw2012_making_opponents_fly/next2.png)](/img/nfsmw2012_making_opponents_fly/next2.png)

``584,104`` results
Let's drive to another place, of course ``z`` will change (changes that it will stay the same are very very low), so we scan for changed value (we don't know if it increased or decreased).

[![431,126 results](/img/nfsmw2012_making_opponents_fly/standing.png)](/img/nfsmw2012_making_opponents_fly/standing.png)

``431,126`` results
We keep filtering this way, using the increased, decreased, changed, unchanged scan types, and we end up with ``337`` results

[![337 results](/img/nfsmw2012_making_opponents_fly/337.png)](/img/nfsmw2012_making_opponents_fly/337.png)

Now that all the results look <more or less> related to the ``z`` coordinate of our car, let's start trying them one-by-one, each time, we incease the value, and we see if there is any change in the game, if there is none, we revert back our changes.
We select all the results, then click the red arrow next to the scan results, and we start testing them one by one.

[![z coordinate found](/img/nfsmw2012_making_opponents_fly/found_z.png)](/img/nfsmw2012_making_opponents_fly/found_z.png)

We found it, address = ``0AEA88B4`` (it will change each time you restart the game/sometimes when you crash your car, or change it, because of Dynamic memory Allocation)

(Small note : coordinates are most of the time on the same structure, we found the address of the ``z`` coordinate of our car, we can easily find the other coordinates, the gravity that affects it, the rotation angles, the speed vector etc.)

Now that we found the address of our ``z`` coordinate, we will try to find out what accesses it (by putting an ``on access`` breakpoint on it), we will rightclick that entry, and choose ``Find out what accesses this address``

[![onread breakpoint](/img/nfsmw2012_making_opponents_fly/read_breakpoint.png)](/img/nfsmw2012_making_opponents_fly/read_breakpoint.png)

There are a dozen instructions, most of them will probably access other variables (coordinates of other objects I guess), we will first try to find one instruction that only accesses this address, no others, to do that, we will add all the results to our codelist, then, we will test them one by one : select, then to find out what addresses they access, and check if there is only our car's structure (testing can take time, we must be sure)

[![Code accessing only my car coordinates](/img/nfsmw2012_making_opponents_fly/accesses_only_mine.png)](/img/nfsmw2012_making_opponents_fly/accesses_only_mine.png)

Awesome, not only we found some code that accesses only the height of our car, but it also executes very often (it executes even when the game is paused), to keep track of our height (and avoing scanning for it in the future), we will do this:
- Inject some code using the found instruction as an injection point (remplace the instruction with a ``jmp`` to a codecave of ours, run our code there, run original code then return to where we left.
- Our code will just save the address of the height of our car somewhere where we will find it easily (register a symbol), actually, instead of saving the height address, we will save the base address of the structure (``height address - 0x34``, which is the content of the ``ecx`` register)
The code will be simple, this will do:

```nasm
[enable]
alloc(log_player,1024)
label(player_car) // player_car+30={x,z,y}
registersymbol(player_car)
label(returnlog)
log_player:
mov [player_car], ecx // save base of structure in the address player_car
db 0f 28 41 30 0f 5c 44 24 60 // ORIGINAL CODE THAT WE PATCHED WITH A JMP
jmp returnlog  // return to where we left
player_car:
dd 0   // initialize the content of player_car with 0
"NFS13.exe"+4F7C65:
jmp log_player // jump to our allocated memory
db 90 90 90 90 // FILL WITH NOPS
returnlog:
[disable]
dealloc(log_player)
"NFS13.exe"+4F7C65:
db 0f 28 41 30 0f 5c 44 24 60
unregistersymbol(player_car)
```
When the box on the left of the script will be ticked, the code in ``[enable]`` will run, creating a symbol player_car that points to the address of the coordinates of our car, and when unticked, it will restore the original code.
We delete all the addresses from our address list, and we add that script (``CTRL+ALT+A``, paste the script, ``File->Assign to current cheat table``)

[![Log Player Car](/img/nfsmw2012_making_opponents_fly/log_player_car.png)](/img/nfsmw2012_making_opponents_fly/log_player_car.png)

We activate the script by ticking its box in the address list, then we click ``add address manually``, we select Pointer, we enter ``player_car`` (it's the symbol that we registered, Cheat Engine will resolve it), and we set the offset to ``0x34`` (our height is at offset ``0x34`` in our structure)

[![Pointer](/img/nfsmw2012_making_opponents_fly/pointer.png)](/img/nfsmw2012_making_opponents_fly/pointer.png)

Bingo, we got a pointer to our car height, we will never have to scan for it again.

We can even assign a hotkey that will increase the height of our car by a constant (rightclick on it ``-> Set/Change Hotkeys``).

Now we will try to find some code that accesses the structures of the opponents (cops and race opponents), if we find some code that does not access our car's structure, it will be better (code injection would not affect our car), but such a code isn't required, any code that accesses our targeted opponents structures will do.

What to do now? two solutions are possible:
- To try to find a difference between the structure of our car and the other structures using the structure dissector (find a field that indicates that it's the player's car for example), then in our injected code, check the content of that field and if it's our car, don't do anything, otherwise increase ``z`` by a given height.

- In the injected code, to compare the base address of the structure with the one that we saved when we logged the base address of our player car (``player_car`` symbol), if it's equal, then it's our car, otherwise it's an opponent.

I chose the second option, because the first one is not guaranteed to work.

Next step : find some code that accesses the cars that we want to affect (cops and race opponents), we will:
- find the height address of an opponents car by finding out what some of these instructions access.
- find out what accesses the height of the opponents car, and check the results one by one.

[![Shared Code](/img/nfsmw2012_making_opponents_fly/shared_code.png)](/img/nfsmw2012_making_opponents_fly/shared_code.png)

The code at address ``"NFS13.exe"+5903E6`` looks perfect, as shown in the picture, three of the results are the base addresses of the cops cars, and the fourth one is the one of my car, we also tested it on race opponents, and it accessed them.

[![Disassembly](/img/nfsmw2012_making_opponents_fly/disassembly.png)](/img/nfsmw2012_making_opponents_fly/disassembly.png)

Looking at that code, there are other advantages:
- The ``jmp`` to our codecave will take ``5`` bytes, so we will need to add ``3`` nops, and the patched instructions are not position-dependent like relative ``jmps`` etc.
- ``ecx`` and ``edx`` are overwritten just after that instruction, so we are free to use them in our code (without the need to ``push``/``pop`` them)

- Our code will run for ``5ms`` each time a hotkey is pressed (I chose ``E``), increasing the height of each car by ``20m``, and adding it to an array, in order to keep track of it, let's write some pseudocode that will help us writing the final thing in assembly

- The hotkey will just set ``activated`` to ``1``

```clike
[OUR VARIABLES]
activated = 0; // if set to 1, the cheat will run for 5ms

start_time = 0;
player_car; // base address of our car structure
carscount = 0;
cars[] // An array, almost a page of free memory, empty initially
[CODE THAT WILL RUN ON EACH CAR IN SIGHT (cops, race opponents, our car)]
if (activated == 1)
{
    time = getTickCount(); // get current process time in ms
    if (start_time == 0)
        start_time = time;
    if (time - start_time <= 5)
    {
        // still active
        if (player_car != base_of_structure) // player_car is the base of the structure of our car
        {
            // it's an opponent's car
            found = 0
            for each car in cars
                if (car == base_of_structure) found = 1 // search for base_of_structure in the cars array
            if (found == 0)
            {
                // not found in cars array, it means that it's the first time we encounter that car
                base_of_structure.z += 20 // increase height by 20m
                cars[carscount] = base_of_structure // add it to cars array, to avoid increasing the height more than once on a 5ms interval
                carscount += 1
            }
        }
    }
    else
    {
        // more than 5 ms have passed, clean the cars array and set activated to 0
        activated = 0
        start_time = 0
        for i = 0 to carscount
            car[i] = 0
        carscount = 0
    }
}
```
By using meaningful label names, string instructions with prefixes (``repne scasd``, ``rep stosd``), our code has remained short and readable.
 Full code here

```nasm
[enable]
assert(player_car,**)
alloc(forall,1024)
label(start_time)
label(amount)
label(alreadystarted)
label(clean_and_skip)
label(carscount)
label(returnforall)
label(activated)
registersymbol(activated)
forall:
cmp byte ptr[activated], 0
jz skip
// ITS ACTIVATED
push edi
push eax
call GetTickCount
mov ecx, [start_time]
test ecx, ecx
jnz alreadystarted
mov [start_time], eax
alreadystarted:
	sub eax,[start_time]
	cmp eax, 5
	pop eax
	jle stillactive
	// No longer active, desactivate the cheat
	mov byte ptr[activated], 0
	mov [start_time], 0
	//CLEAN ARRAY
	mov ecx, [carscount]
	lea edi, [cars]
	push eax
	xor eax, eax
	rep stosd
	mov [carscount],0
	pop eax
	jmp clean_and_skip
stillactive:
	mov edi,[player_car]
	cmp edi, eax
	jz clean_and_skip
	lea edi, [cars]
	// SEARCH FOR eax IN cars ARRAY
	mov ecx, [carscount]
	repne scasd
	jz clean_and_skip
	//NOT FOUND IN ARRAY, AND NOT MY CAR
	mov [edi], eax // INSERT IN ARRAY
	inc [carscount]
	// MAKE IT FLY
	fld [eax+34]
	fadd [amount]
	fstp [eax+34]

clean_and_skip:
pop edi
skip:
db 0f 28 40 30 8b 44 24 04
jmp returnforall

activated:
db 0
start_time:
dd 0
amount:
dd (float)20.0
carscount:
dd 0
cars:
"NFS13.exe"+5903E6:
jmp forall
db 90 90 90
returnforall:
[disable]
dealloc(forall)
"NFS13.exe"+5903E6:
db 0f 28 40 30 8b 44 24 04
unregistersymbol(activated)
```
In its ``[disable]`` section, we will just dealloc our allocated memory, and we'll restore the original code, now we'll add the script to our cheat table.
In order to activate the script, we need to set ``activated`` to ``1``, this small Lua script will create the hotkey ``E``, that when clicked, sets ``activated`` to ``1``

```lua
copsfly = createHotkey(function()
  return writeBytes('activated', 1)
end, VK_E)
```
We will save it on our cheat table (``table -> Show Cheat Table Lua Script``).
Let's test it, and with different cars (to ensure that our cheat always works).

[![Flying Cops](/img/nfsmw2012_making_opponents_fly/flying_cops.png)](/img/nfsmw2012_making_opponents_fly/flying_cops.png)

Cool, I can make cops fly :p
On race opponents :

[![Flying Opponents](/img/nfsmw2012_making_opponents_fly/flying_opponents.png)](/img/nfsmw2012_making_opponents_fly/flying_opponents.png)

It works!

(Note : addresses might differ on different game versions, I am using Black Box Repack version)

I hope you've enjoyed the tutorial

Stay tuned for more! 
