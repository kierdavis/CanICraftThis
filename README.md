# CanICraftThis

## Installation

1.  Head to the [release list][releases].

2.  Download `CanICraftThis-N.zip` for the latest release.

3.  Open the downloaded file, and copy the `CanICraftThis` folder contained
    within.

4.  Navigate to `Documents\Elder Scrolls Online\live\AddOns` and paste the
    previously copied folder here.

5.  If Elder Scrolls Online is currently running, open the chat bar and type
    `/reloadui` to load the addon. If not, the addon will be loaded the next
    time the game is launched.

## Support

Feel free to [open an issue on this repository][issues] or send an in-game mail
to `@always.ada` if you have any problems. I work on this in my free time, so
I don't provide any guarantees on when/if I will respond, but I try my best.

## Known bugs

* As of APIVersion 100034, ESO has a bug in its collectibles database
  (as accessed via `GetCollectibleInfo`). Two collectible IDs (6117 and 6131)
  both yield the same name "Honor Guard Jerkin", and no collectible ID yields
  the name "Honor Guard Jack" despite multiple community wikis implying that
  it should exist. As a result, undefined behaviour will occur when rendering
  the tooltip for a Jerkin or Jack writ in the Honor Guard style.

## License

[LICENSE.txt](LICENSE.txt)


[releases]: https://github.com/kierdavis/CanICraftThis/releases
[issues]: https://github.com/kierdavis/CanICraftThis/issues
