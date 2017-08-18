docker:
	docker build -t jeasterman/tsung-docker .

.PHONY: docker-ssh
docker-ssh:
	docker run -ti --entrypoint='bash' jeasterman/tsung-docker:latest

.PHONY: docker-run
docker-run:
	docker run -v /local/tests:/usr/local/tsung \
	--name tsung-agent \
	jeasterman/tsung-docker \
	-f /usr/local/tsung/tsung.xml \
	-p 21:22 \
	-r \"ssh -p 22\" \
	start

.PHONY: docker-attach
docker-attach:
	docker exec -i -t tsung-agent bash

.PHONY: docker-stop
docker-stop:
	docker stop tsung-agent
	docker rm tsung-agent



