OUTPUT_DIR := output/pdf
QA_CHAPTER_SOURCES := $(wildcard interview-qa/chapter-*.typ)
QA_CONTENT_SOURCES := $(wildcard interview-qa/chapters/*.typ) interview-qa/style.typ
QA_CHAPTER_PDFS := $(patsubst interview-qa/chapter-%.typ,$(OUTPUT_DIR)/execution-interview-qa-chapter-%.pdf,$(QA_CHAPTER_SOURCES))

.PHONY: book qa-chapters all watch clean

book:
	mkdir -p $(OUTPUT_DIR)
	typst compile main.typ $(OUTPUT_DIR)/stochastic-control-algorithmic-trading.pdf

$(OUTPUT_DIR)/execution-interview-qa-chapter-%.pdf: interview-qa/chapter-%.typ $(QA_CONTENT_SOURCES)
	mkdir -p $(OUTPUT_DIR)
	typst compile $< $@

qa-chapter-%: $(OUTPUT_DIR)/execution-interview-qa-chapter-%.pdf

qa-chapters: $(QA_CHAPTER_PDFS)

all: book qa-chapters

watch:
	mkdir -p $(OUTPUT_DIR)
	typst watch main.typ $(OUTPUT_DIR)/stochastic-control-algorithmic-trading.pdf

clean:
	rm -f $(OUTPUT_DIR)/stochastic-control-algorithmic-trading.pdf $(OUTPUT_DIR)/execution-interview-qa-chapter-*.pdf
