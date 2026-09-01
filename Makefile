.PHONY: book qa qa-chapter-01 all watch clean

book:
	mkdir -p build
	typst compile main.typ build/book.pdf

qa:
	mkdir -p build
	typst compile interview-qa/main.typ build/execution-interview-qa.pdf

qa-chapter-01:
	mkdir -p build
	typst compile interview-qa/chapter-01.typ build/execution-interview-qa-chapter-01.pdf

all: book qa qa-chapter-01

watch:
	mkdir -p build
	typst watch main.typ build/book.pdf

clean:
	rm -f build/book.pdf build/execution-interview-qa.pdf build/execution-interview-qa-chapter-*.pdf
