# CanICraftThis

## Support

Feel free to [open an issue on this repository][issues] or send an in-game mail
to `@always.ada` if you have any problems. I work on this in my free time, so
I don't provide any guarantees on when/if I will respond, but I try my best.

## Known bugs

* As of APIVersion 100033, ESO has a bug in its collectibles database
  (as accessed via `GetCollectibleInfo`). Two collectible IDs (6117 and 6131)
  both yield the same name "Honor Guard Jerkin", and no collectible ID yields
  the name "Honor Guard Jack" despite multiple community wikis implying that
  it should exist. As a result, undefined behaviour will occur when rendering
  the tooltip for a Jerkin or Jack writ in the Honor Guard style.

## License

[LICENSE.txt](LICENSE.txt)
