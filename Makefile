OUTPUT_DIR := output/pdf
QUARTO ?= quarto
QA_CHAPTER_SOURCES := $(wildcard interview-qa/chapter-*.typ)
QA_CONTENT_SOURCES := $(wildcard interview-qa/chapters/*.typ) interview-qa/style.typ
QA_CHAPTER_PDFS := $(patsubst interview-qa/chapter-%.typ,$(OUTPUT_DIR)/execution-interview-qa-chapter-%.pdf,$(QA_CHAPTER_SOURCES))

.PHONY: book qa-chapters all watch clean web web-preview check-port check-web

book:
	mkdir -p $(OUTPUT_DIR)
	typst compile main.typ $(OUTPUT_DIR)/stochastic-control-algorithmic-trading.pdf

$(OUTPUT_DIR)/execution-interview-qa-chapter-%.pdf: interview-qa/chapter-%.typ $(QA_CONTENT_SOURCES)
	mkdir -p $(OUTPUT_DIR)
	typst compile $< $@

qa-chapter-%: $(OUTPUT_DIR)/execution-interview-qa-chapter-%.pdf

qa-chapters: $(QA_CHAPTER_PDFS)

all: book qa-chapters

web:
	$(QUARTO) render web --to html

web-preview:
	$(QUARTO) preview web

check-port:
	QUARTO="$(QUARTO)" python3 scripts/port_typst.py --check

check-web:
	python3 scripts/check_web.py

watch:
	mkdir -p $(OUTPUT_DIR)
	typst watch main.typ $(OUTPUT_DIR)/stochastic-control-algorithmic-trading.pdf

clean:
	rm -f $(OUTPUT_DIR)/stochastic-control-algorithmic-trading.pdf $(OUTPUT_DIR)/execution-interview-qa-chapter-*.pdf
