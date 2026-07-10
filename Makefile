NVC       := nvc
STD       := --std=2008
TOP       := counter_tb
WAVE_DIR  := waves
WAVE_FILE := $(WAVE_DIR)/$(TOP).fst

SRC := src/counter.vhd
TB  := tb/counter_tb.vhd

.PHONY: all analyze elaborate run wave clean

all: run

analyze:
	$(NVC) $(STD) -a $(SRC)
	$(NVC) $(STD) -a $(TB)

elaborate: analyze
	$(NVC) $(STD) -e $(TOP)

run: elaborate
	mkdir -p $(WAVE_DIR)
	$(NVC) $(STD) -r $(TOP) \
		--stop-time=120ns \
		--wave=$(WAVE_FILE)

wave:
	surfer $(WAVE_FILE)

clean:
	rm -rf work
	rm -f $(WAVE_DIR)/*.fst