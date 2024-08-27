# Elite Universe Editor on the BBC Micro with a 6502 Second Processor

![The Elite Universe Editor on the BBC Micro](https://elite.bbcelite.com/images/github/elite-universe-editor-home-screen.png)

This repository contains source code for the Elite Universe Editor on the BBC Micro with a 6502 Second Processor. You can build it using `make`.

The Elite Universe Editor allows you to create your own universes in classic BBC Micro and Commodore 64 Elite. For more information, see the [bbcelite.com website](https://elite.bbcelite.com/hacks/elite_universe_editor.html).

This repository contains the Universe Editor code as a submodule:

* [Elite Universe Editor Library](https://github.com/markmoxon/library-elite-universe-editor)

This code is patched into Elite. You can search the source code for the patch points by searching the sources for `Mod:`. This repository is downstream from the [6502 Second Processor Elite](https://github.com/markmoxon/6502sp-elite-beebasm) repository, and can be updated by pulling from the `main` branch upstream.

The following repositories are used to generate the Universe Editor for the different platforms:

* [BBC Master Elite Universe Editor](https://github.com/markmoxon/master-elite-universe-editor)
* [6502 Second Processor Elite Universe Editor](https://github.com/markmoxon/6502sp-elite-universe-editor)
* [Commodore 64 Elite Universe Editor](https://github.com/markmoxon/c64-elite-universe-editor)

The above repositories are used when building the Universe Editor and the Elite Compendium discs:

* [Elite Universe Editor](https://github.com/markmoxon/elite-universe-editor)
* [Elite Compendium (BBC Master)](https://github.com/markmoxon/elite-compendium-bbc-master)
* [Elite Compendium (BBC Micro)](https://github.com/markmoxon/elite-compendium-bbc-micro)

In all cases, child code is included in a parent using a submodule.

## Acknowledgements

6502 Second Processor Elite was written by Ian Bell and David Braben and is copyright &copy; Acornsoft 1985.

The code on this site is identical to the source discs released on [Ian Bell's personal website](http://www.elitehomepage.org/) (it's just been reformatted to be more readable).

The commentary is copyright &copy; Mark Moxon. Any misunderstandings or mistakes in the documentation are entirely my fault.

Huge thanks are due to the original authors for not only creating such an important piece of my childhood, but also for releasing the source code for us to play with; to Paul Brink for his annotated disassembly; and to Kieran Connell for his [BeebAsm version](https://github.com/kieranhj/elite-beebasm), which I forked as the original basis for this project. You can find more information about this project in the [accompanying website's project page](https://elite.bbcelite.com/about_site/about_this_project.html).

The following archive from Ian Bell's personal website forms the basis for this project:

* [6502 Second Processor sources as a disc image](http://www.elitehomepage.org/archive/a/a5022201.zip)

### A note on licences, copyright etc.

This repository is _not_ provided with a licence, and there is intentionally no `LICENSE` file provided.

According to [GitHub's licensing documentation](https://docs.github.com/en/free-pro-team@latest/github/creating-cloning-and-archiving-repositories/licensing-a-repository), this means that "the default copyright laws apply, meaning that you retain all rights to your source code and no one may reproduce, distribute, or create derivative works from your work".

The reason for this is that my commentary is intertwined with the original Elite source code, and the original source code is copyright. The whole site is therefore covered by default copyright law, to ensure that this copyright is respected.

Under GitHub's rules, you have the right to read and fork this repository... but that's it. No other use is permitted, I'm afraid.

My hope is that the educational and non-profit intentions of this repository will enable it to stay hosted and available, but the original copyright holders do have the right to ask for it to be taken down, in which case I will comply without hesitation. I do hope, though, that along with the various other disassemblies and commentaries of this source, it will remain viable.

---

Right on, Commanders!

_Mark Moxon_