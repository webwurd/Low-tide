# Narrative outline (canon: the tape text in `dialogue/dialogue.json` wins over this summary)

## Truth timeline
- **1974, Project Pelagic**: a Navy + university hydrophone array run from Gannet Rock. Keeper **Walt Haskell** hosts; his wife **June Haskell**, an acoustician, services the cable splices.
- **4 Nov 1974**: June goes to splice 2 in the south reef cable vault. **Lt. Hayes** says the Navy schedule gives two hours of low water; the tide table (and Coast Guard boatswain **Tom Dunmore**, Clara's father) say one. Tom waits offshore with his engine running and watches the water come over the bar. June does not come out. Her field recorder stays in the vault. The Navy report says "lost at sea, weather" and that June was never on the manifest.
- **1976-1979**: Walt records cassette letters to June (tapes 1, 3, 4). In 1977 the Navy offers a settlement with a non-disclosure line; he refuses. In March 1979 he leaves the rock, leaving his tapes in the lantern-room locker "for whoever's next", and names June's sister **Ruth Whitcomb** (Wickenden Street, Providence) as the person who should have them.
- **After**: Tom Dunmore stops going out and leaves a boat-log cassette in a biscuit tin at the cove hut (tape 5). His daughter **Clara** becomes a Coast Guard dispatcher and, for years, quietly services the west cave buoy's battery (tape 6): its hydrophone hears a ping every 14 seconds from the reef. She tells herself it is June's recorder. It is the splice transponder. Grief, not fact.
- **1998 (the game)**: **Arthur**, a recently widowed schoolteacher (his wife, **Maren**, died in the autumn), takes the winter post alone. The only voice he speaks to is Clara's, on channel 16 from **Station Penobscot** (fictional).

## The seven days
| Day | Weather | Beats |
|---|---|---|
| 1 First Watch | Fog | Rituals; east bar; canister (report / withhold) |
| 2 Grey Water | Overcast | West cave; warm buoy; tape 1 (Walt, 1976); first honesty test about the tape |
| 3 Wool | Dense fog | Bell buoys; north cove cable; tape 3 under the floorboard (Walt, 1977; the Navy's offer; Ruth) |
| 4 The Blow | Storm | Indoor day; tape 4 in the lantern locker (Walt, last); Clara's midday call; "My father worked the Pelagic boats"; Arthur's wife |
| 5 Spring Low | Clear | South causeway opens (about 2 hours); vault; tape 2 (June, 1974) |
| 6 Frost | Cold, clear | Cove tin (tape 5: Tom's log) and buoy service hatch (tape 6: Clara); the confrontation in three trust tiers |
| 7 Last Light | Still | The final decision and dawn |

## Trust and the three endings
Trust is a hidden integer moved by honest answers (+) and withholds/lies (-). Over the week it spans roughly **-16 (every withhold) to +23 (every honest answer)**.
- **Day 6 evening confrontation** (by trust at that point): **>= 12** Clara tells everything (`clara_admitted`); **>= 3** she tells some (`clara_partial`); below that she stonewalls (`clara_stonewalled`), unless Arthur holds her own tape (tape 6), which gets him the partial route.
- **Day 7 final choice**: `clara_admitted` offers **A** (send the tapes to Ruth Whitcomb) and **B** (let the buoy die, keep it between us). Otherwise **A** and **C** (report Clara).
- **A, THE RIGHT ADDRESS** / **B, LEFT QUIET**: dawn on the pier; the relief boat's light seen through the binoculars. **C, ON THE RECORD**: the beam and static.
- A reproducible simulation of the whole week (honest / dishonest / two mixed policies) is part of `tests/run_tests.gd`. Re-run it after changing any trust value or threshold.

## Writing status
Placeholder-quality: Day 1-2 convs were drafted in M4 and have been extended; Days 3-7, tapes 3-6 and all endings were drafted in M6. Everything is editable text in `dialogue/dialogue.json`. A polish/read-aloud pass is expected before release.

## Tape continuity (beta rewrite)
Planted threads the tapes now carry. Keep later writing consistent with them.
- **The card / "the left pocket".** Walt copied the tide table onto a card for June each morning and she kept it in her left pocket. June's "tell Walt, the left pocket" means: *I followed your card.* Her last line is "I wasn't careless. I read the card."
- **"Don't wait up."** June's last words to Walt at the landing (tape 3). He waited all night. Ruth keeps asking what June said. Good material for ending A, and for Ruth if she ever speaks.
- **Egg sandwich, too much pepper.** Walt's sandwiches (tape 1) are the only warm thing June eats in the vault (tape 2).
- **The vault sits lower than the bar.** Tom told Hayes it would go under first (tape 5). June finds out the hard way (tape 2). The swell also brought the water early, so the Navy's "weather" story is half true and wholly beside the point.
- **The 14-second ping** is on tape 1 in Walt's own voice, counted aloud. He asks Hayes; Hayes says "test tone." Clara's tape 6 gives the true answer.
- **Clara has heard tape 1.** She has serviced the buoy for years and has never taken Walt's tape out of the main hatch. On day 2 she knows exactly what Arthur has found, which is why she lies about the warmth. Her own tape is left under the *service* hatch so the two don't touch.
- **Walt's advice (tape 4).** "If somebody's out there, answer them. A machine is a poor place to keep a life." A voice on sixteen asked after Walt at ten every night, never more than the weather. Clara does the same for Arthur ("I'll be on sixteen at ten, like always").
- **Tom's tape** closes on "I've a girl at home who's four." Clara was four in 1974. She is 27 on tape 6 (October 1997) and 28 in the game.
