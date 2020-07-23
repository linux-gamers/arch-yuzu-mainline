FROM linuxgamers/arch-yuzu-build

ARG GIT_USER
ARG GIT_EMAIL 
ARG GITHUB_TOKEN
ARG TAG

RUN git clone --recursive -b "mainline-${TAG}" --depth 1 https://github.com/yuzu-emu/yuzu-mainline.git

WORKDIR yuzu-mainline

RUN git checkout -b "${TAG}" && mkdir build && cd build && \ 
	cmake .. -GNinja && \
	ninja -j4

WORKDIR /

RUN git clone https://${GITHUB_TOKEN}@github.com/linux-gamers/arch-yuzu-mainline.git && \
	cd arch-yuzu-mainline && \
    /bin/cp /yuzu-mainline/build/bin/yuzu . && \
	/bin/cp /yuzu-mainline/build/bin/yuzu-cmd . && \
	/bin/cp /yuzu-mainline/dist/yuzu.desktop . && \
	/bin/cp /yuzu-mainline/dist/yuzu.svg . && \
	git config user.name "${GIT_USER}" && \
	git config user.email "${GIT_EMAIL}" && \
	git add . && \
	git commit -m "[RELEASE ${TAG}]" && \
	git push -q https://${GITHUB_TOKEN}@github.com/linux-gamers/arch-yuzu-mainline.git master

RUN curl -X POST -H "Content-Type: application/json" -d "{ \
		\"tag_name\": \"${TAG}\", \
  		\"target_commitish\": \"master\", \
  		\"name\": \"${TAG}\", \
  		\"draft\": false, \
  		\"prerelease\": false \
	}" https://${GITHUB_TOKEN}@api.github.com/repos/linux-gamers/arch-yuzu-mainline/releases
