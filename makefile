.DEFAULT_GOAL := preview

.PHONY: preview
preview:
	hugo server -D

.PHONY: build
build:
	hugo
