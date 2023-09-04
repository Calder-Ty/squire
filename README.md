# SQUIRE

> “Destiny guides our fortunes more favorably than we could have expected. Look
> there, Sancho Panza, my friend, and see those thirty or so wild giants, with
> whom I intend to do battle and kill each and all of them, so with their
> stolen booty we can begin to enrich ourselves. This is nobel, righteous
> warfare, for it is wonderfully useful to God to have such an evil race wiped
> from the face of the earth." 
>
> "What giants?" Asked Sancho Panza. 
>
> "The ones you can see over there," answered his master, "with the huge arms,
> some of which are very nearly two leagues long." 
>
> "Now look, your grace," said Sancho, "what you see over there aren't giants,
> but windmills, and what seems to be arms are just their sails, that go around
> in the wind and turn the millstone."
>
> "Obviously," replied Don Quixote, "you don't know much about adventures.”

Squire: An upgraded Pager

## Motivation

This is a project that provides an improved pager (for example `more` and `less`).

### Goals:

- [] Easy Coloring (Squire should work with coloring out of the box)
    - [] Look at Ansi styling (see rusts `anstyle` family of crates)
    - [] look at termcap/terminfo (I know that less uses termcap)

- [] Feature Parity with `less`
    - Less is the default pager in most distros, so we should be 
    able to do as good as that.

- [] Movement between pages (stretch)
    - I hate having to open man pages by going back to the terminal, It would
    be nice to jump between them. This may have to be something that
    `eve` handles however. Or some sort of integration.

