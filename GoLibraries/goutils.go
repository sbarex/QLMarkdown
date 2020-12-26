package main

import (
	"C"
	"github.com/go-enry/go-enry/v2/data"
	"path/filepath"
	"strings"

	"github.com/go-enry/go-enry/v2"
)

// Functions for conversion between C and Go strings. Required here because cgo cannot be used in
// tests.

func convertToCString(goString string) *C.char {
	return C.CString(goString)
}

func convertToGoString(cString *C.char) string {
	return C.GoString(cString)
}

// 0 <= index <= len(a)
func insert(a []enry.Strategy, index int, value enry.Strategy) []enry.Strategy {
	if len(a) == index { // nil or empty slice or after last element
		return append(a, value)
	}
	a = append(a[:index+1], a[index:]...) // index < len(a)
	a[index] = value
	return a
}

// GetLanguagesByContent returns a slice of languages for the given content.
// It is a Strategy that uses content-based regexp heuristics and a filename extension.
func GetLanguagesByContent2(filename string, content []byte, _ []string) []string {
	if filename == "" {
		return nil
	}

	ext := strings.ToLower(filepath.Ext(filename))

	if ext != "" {
		return nil
	}
	result := []string {}
	for _, heuristic := range data.ContentHeuristics {
		r := heuristic.Match(content)
		if len(r) > 0 {
			result = append(result, r...)
		}
	}
	return result
}

var initialized = false

//export initEnryEngine
func initEnryEngine() {
	if !initialized {
		enry.DefaultStrategies = insert(enry.DefaultStrategies, len(enry.DefaultStrategies)-1, GetLanguagesByContent2)
	}
	initialized = true
}

func BytesToString(data []byte) string {
	return string(data[:])
}

//export guessWithEnry
func guessWithEnry(content []byte) *C.char {
	lang := enry.GetLanguage("-", content)
	// fmt.Println(BytesToString(content))
	// fmt.Println("Lang: ", lang)
	return convertToCString(lang)
}

// Main function is required for `c-archive` builds.
func main() {
	/*
	argsWithoutProg := os.Args[1:]

	initEnryEngine()

	for _, filename := range argsWithoutProg {
		content, err := ioutil.ReadFile(filename)
		if err == nil {
			lang := convertToGoString(guessWithEnry(content))

			exts := []string{}
			if lang != "" {
				exts = enry.GetLanguageExtensions(lang)
			}
			fmt.Println(filename, ": ", lang, " ", exts)
		}
	}
	*/
}
