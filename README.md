# Balatro Web

This project lets you play Balatro in your browser.

It extracts the assets and code from the original game, applies patches, and runs it using a modified version of [love2D.js](https://github.com/2dengine/love.js).

> You need to own an original copy of Balatro, such as the [Steam version](https://store.steampowered.com/app/2379780/Balatro/).

## Usage

```
# Put Balatro.exe at the root of the repository
make unpack
make build
make run
```

Open your browser on `http://127.0.0.1:7777` and enjoy!

## Limitations

- Audio is currently not supported.
