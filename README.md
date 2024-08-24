# Simperium

## What is it?

A NetLogo-based combat simulator for Twilight Imperium (4th Edition).

## What's unsupported?

  * Some expansion content (like mechs)
  * The Yin faction
  * Action Cards
  * Promissory Notes
  * And more

## What's good about it?

I was inspired to make this after being disappointed that other simulators had no visualization or feedback on the details of the outcome.  They would just tell you, "you have an 87% chance of winning this battle".  But... what would the typical victory or failure look like?  Were my forces likely to win with minimal losses, or to win pyrrhic victories?  If the enemy won, how much of a setback should I expect that to be for them?  Just giving me the win percentage wasn't helping me enough to make informed decisions, so I made this to be able to understand the anecdotes, along with being able to generate the data.

To generate the data, you can batch-run scenarios with NetLogo's BehaviorSpace functionality, and then analyze the resulting CSV file.

## How do I use it?

Open the `.nlogo` file in NetLogo 6.4.0 or later (or in NetLogo Web).  Plug in your configuration in the "Interface" tab.  Turn the "speed" slider down so you can watch things happen more slowly.  Click "setup".  Click "go".

## I found a bug!

Cool.  Please report it on the issue tracker so I can fix it.

## License?

Yes, BSD-3.
