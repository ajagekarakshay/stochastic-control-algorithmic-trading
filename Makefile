QA_CHAPTER_SOURCES := $(wildcard interview-qa/chapter-*.typ)
QA_CONTENT_SOURCES := $(wildcard interview-qa/chapters/*.typ) interview-qa/style.typ
QA_CHAPTER_PDFS := $(patsubst interview-qa/chapter-%.typ,build/execution-interview-qa-chapter-%.pdf,$(QA_CHAPTER_SOURCES))

.PHONY: book qa qa-chapters all watch clean

book:
	mkdir -p build
	typst compile main.typ build/book.pdf

qa:
	mkdir -p build
	typst compile interview-qa/main.typ build/execution-interview-qa.pdf

build/execution-interview-qa-chapter-%.pdf: interview-qa/chapter-%.typ $(QA_CONTENT_SOURCES)
	mkdir -p build
	typst compile $< $@

qa-chapter-%: build/execution-interview-qa-chapter-%.pdf

qa-chapters: $(QA_CHAPTER_PDFS)

all: book qa qa-chapters

watch:
	mkdir -p build
	typst watch main.typ build/book.pdf

clean:
	rm -f build/book.pdf build/execution-interview-qa.pdf build/execution-interview-qa-chapter-*.pdf
