export EMACS ?= $(shell which emacs)
ORG_DIR1 = -L $(word 1,$(wildcard $(HOME)/.emacs.d/elpa/org-9*))
ifeq ($(words $(ORG_DIR1)),1)
	ORG_DIR1 =
endif
ORG_LIB = -l org -l ox-texinfo
ORG_PUB = --eval='(progn (find-file (expand-file-name "README.org")) (org-texinfo-export-to-info))'
EMACS_ARGS = --batch $(ORG_DIR1) $(ORG_LIB) $(ORG_PUB)

all:
	echo all

CASK = cask
ifdef CASK
	CASK_DIR := $(shell cask package-directory)
endif

$(CASK_DIR): Cask
	$(CASK) install
	@touch $(CASK_DIR)

.PHONY: cask
cask: $(CASK_DIR)

.PHONY: compile
compile: $(CASK)
	$(CASK) emacs -batch -L . -L test \
	--eval "(setq byte-compile-error-on-warn t)" \
	-f batch-byte-compile $$(cask files); \
	(ret=$$? ; cask clean-elc && exit $$ret)

.PHONY: test coverage
test:
	rm -rf coverage
	$(CASK) exec buttercup -L .

coverage: test
	genhtml -o coverage/ coverage/lcov.info

# The file where the version needs to be replaced
TARGET_FILE = org-noter.el

# Target to display the current version without overwriting the VERSION file
current-version:
	@CURRENT_VERSION=$$(svu current); \
	echo "Current Version: $$CURRENT_VERSION"

# Target to bump the patch version
bump-patch:
	@NEW_VERSION=$$(svu patch); \
	NEW_EMACS_VERSION=$$(echo $$NEW_VERSION | sed 's/^v//'); \
	sed -i.bak -E "s/^;; Version:.*/;; Version: $$NEW_EMACS_VERSION/" $(TARGET_FILE); \
	echo "New Patch Version: $$NEW_VERSION"; \
	git add $(TARGET_FILE); \
	git commit -m "Bump patch version to $$NEW_VERSION"; \
	git tag "$$NEW_VERSION"; \
	echo "Don't forget to push the new tag."


# Target to bump the minor version
bump-minor:
	@NEW_VERSION=$$(svu minor); \
	NEW_EMACS_VERSION=$$(echo $$NEW_VERSION | sed 's/^v//'); \
	sed -i.bak -E "s/^;; Version:.*/;; Version: $$NEW_EMACS_VERSION/" $(TARGET_FILE); \
	echo "New Patch Version: $$NEW_VERSION"; \
	git add $(TARGET_FILE); \
	git commit -m "Bump minor version to $$NEW_VERSION"; \
	git tag "$$NEW_VERSION"; \
	echo "Don't forget to push the new tag."

.PHONY: current-version bump-patch bump-minor

info: README.org
	$(EMACS) $(EMACS_ARGS)
	install-info README.info dir
