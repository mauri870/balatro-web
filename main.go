package main

import (
	"embed"
	"io/fs"
	"log"
	"net/http"
	"os"
)

//go:embed index.html style.css player.js game.love lua 11.3 11.4 11.5
var static embed.FS

func main() {
	addr := os.Getenv("ADDR")
	if addr == "" {
		addr = ":7777"
	}

	sub, err := fs.Sub(static, ".")
	if err != nil {
		log.Fatal(err)
	}

	fileServer := http.FileServer(http.FS(sub))

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cross-Origin-Opener-Policy", "same-origin")
		w.Header().Set("Cross-Origin-Embedder-Policy", "require-corp")
		// index.html uses <base href="/play/">, rewrite those requests to the root
		if len(r.URL.Path) >= 6 && r.URL.Path[:6] == "/play/" {
			r.URL.Path = r.URL.Path[5:]
		}
		fileServer.ServeHTTP(w, r)
	})

	log.Printf("listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, nil))
}
