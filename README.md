# Balatro Web

This project allows you to play Balatro on the web!

It extracts the assets and code from the original game, patches it and then runs a modified version of [love2D.js](https://github.com/2dengine/love.js).

> You need an original copy of Balatro, for example the [Steam Version](https://store.steampowered.com/app/2379780/Balatro/).


## Usage

```
# Put Balatro.exe at the root of the repository
mage unpack
mage build
mage run
```

Open your browser on `http://127.0.0.1:7777` and enjoy!

## Limitations

Currently there is no sound being played. I believe streaming sounds don't currently work with love.js.
