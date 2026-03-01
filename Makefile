.PHONY: build run shell stop clean logs

build:
	./sandbox build

run:
	./sandbox

shell:
	./sandbox shell

stop:
	./sandbox stop

clean:
	./sandbox clean

logs:
	./sandbox logs
