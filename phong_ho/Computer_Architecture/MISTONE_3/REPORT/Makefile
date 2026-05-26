# ==============================
# Makefile cho báo cáo internship
# ==============================

# File chính
MAIN = main
PDF = $(MAIN).pdf

# LaTeX compiler
LATEX = pdflatex
LATEXFLAGS = -interaction=nonstopmode -file-line-error

# Các file section / style phụ thuộc
SECTIONS = $(wildcard sections/*.tex)
STYLE = mystyle.sty

# ==============================
# Default target: build PDF
# ==============================
all: $(PDF)

$(PDF): $(MAIN).tex $(SECTIONS) $(STYLE)
	@echo "==> Compiling $(MAIN).tex ..."
	$(LATEX) $(LATEXFLAGS) $(MAIN).tex
	$(LATEX) $(LATEXFLAGS) $(MAIN).tex  # chạy 2 lần để TOC, refs chính xác
	@echo "==> Build finished: $(PDF)"

# ==============================
# Clean all temp + PDF
# ==============================
clean:
	@echo "==> Cleaning all temp files + PDF ..."
	rm -f *.aux *.log *.out *.toc *.lof *.lot *.bbl *.blg *.synctex.gz *.fdb_* *.fls  $(PDF)
	@echo "==> Clean finished."

# ==============================
# Open PDF
# ==============================
view: $(PDF)
	xdg-open $(PDF) &

# ==============================
# Phony targets
# ==============================
.PHONY: all clean view

