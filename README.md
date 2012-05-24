Hubot-Pim
=========

This is a [Hubot][] adapter for [Pim][].

Set up your own Hubot on Pim
----------------------------

1. Register a new Pim account for your Hubot
2. [Obtain your own Hubot][Hubot] and extract it somewhere
3. Edit `Procfile`:
    - change `campfire` to `pim`
    - change `-n Hubot` to `-n [Hubot's username]`
4. Edit `package.json` - add `"hubot-pim":">=0.1.0",` to the dependencies
5. Run `npm install` to install the dependencies.
6. Create the file `config.json` (see below)
7. Run `bin/hubot -a pim -n [Hubot's username]`

Enjoy your increased (or decreased) productivity!

Config.json
-----------

First you need to get your Hubot's token. Currently the easiest way to
do this is by logging in as Hubot via your web browser and then pasting
the following into your URL bar and pressing enter:

    javascript:alert(P.user.get('token'))

Then create `config.json`:

    { "token": "[token from JavaScript alert]" }

Tokens are (currently) of the format `00000000-0000-0000-0000-000000000000`

[Pim]: https://p.im/
[Hubot]: http://hubot.github.com/
