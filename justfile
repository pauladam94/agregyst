thumbnail:
	typst c examples/coordination.typ --root . -f png 'coordination-{p}.png'
	typst c thumbnail/thumbnail.typ --root . -f png --pages 1 --ppi 200
	oxipng thumbnail/thumbnail.png

# DIR should be equal to the directory where the package will reside
copy_to DIR:
	cp agregyst.typ {{DIR}}/agregyst.typ
	cp utils.typ {{DIR}}/utils.typ
	cp thumbnail/thumbnail.png {{DIR}}/thumbnail.png

	cp typst.toml {{DIR}}/typst.toml
	cp README.md {{DIR}}/README.md
	cp LICENSE {{DIR}}/LICENSE

	rm -f {{DIR}}/template/bib.yaml
	rm -f {{DIR}}/template/main.typ
	rmdir {{DIR}}/template

	mkdir {{DIR}}/template
	cp template/bib.yaml {{DIR}}/template/bib.yaml
	cp template/main.typ {{DIR}}/template/main.typ
