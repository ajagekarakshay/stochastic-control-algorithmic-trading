.PHONY: book watch clean

book:
	mkdir -p build
	typst compile main.typ build/book.pdf

watch:
	mkdir -p build
	typst watch main.typ build/book.pdf

clean:
	rm -f build/book.pdf

