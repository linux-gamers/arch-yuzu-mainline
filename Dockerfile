FROM linuxgamers/arch-yuzu-build

ARG TAG
ARG GIT_USER
ARG GIT_EMAIL 
ARG GITHUB_TOKEN
ARG AUR_SSH_KEY

RUN useradd -ms /bin/bash linuxgamers

USER linuxgamers

RUN git clone --recursive -b "mainline-${TAG}" --depth 1 https://github.com/yuzu-emu/yuzu-mainline.git ~/yuzu-mainline

WORKDIR /home/linuxgamers/yuzu-mainline

RUN git checkout -b "${TAG}" && mkdir build && cd build && \ 
	cmake .. -GNinja && \
	ninja -j4

WORKDIR /home/linuxgamers

RUN git clone https://${GITHUB_TOKEN}@github.com/linux-gamers/arch-yuzu-mainline.git ~/arch-yuzu-mainline && \
	cd arch-yuzu-mainline && \
    /bin/cp ~/yuzu-mainline/build/bin/yuzu . && \
	/bin/cp ~/yuzu-mainline/build/bin/yuzu-cmd . && \
	/bin/cp ~/yuzu-mainline/dist/yuzu.desktop . && \
	/bin/cp ~/yuzu-mainline/dist/yuzu.svg . && \
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


RUN mkdir -p ~/.ssh && \
	echo "$AUR_SSH_KEY" | tr -d '\r' > ~/.ssh/id_rsa && chmod 700 ~/.ssh/id_rsa && \
	ssh-keyscan -H 'aur.archlinux.org' >> ~/.ssh/known_hosts && \
	eval "$(ssh-agent -s)" && \
	ssh-add ~/.ssh/id_rsa && \
	git clone ssh://aur@aur.archlinux.org/yuzu-mainline-bin.git ~/yuzu-mainline-bin

WORKDIR /home/linuxgamers/yuzu-mainline-bin

RUN git config user.name "${GIT_USER}" && git config user.email "${GIT_EMAIL}" && \
	wget "https://github.com/linux-gamers/arch-yuzu-mainline/archive/${TAG}.tar.gz" && \
	VERSION=$(echo ${TAG} | cut -d- -f2) && \
	sed -i -E "s/_pkgver=.+/_pkgver=${VERSION}/" PKGBUILD && \
	SHA=$(sha512sum ${TAG}.tar.gz | grep -Eo "(\w+)\s" | cut -d" " -f1)  && \
	sed -i -E "s/sha512sums=.+/sha512sums=\(\'${SHA}\'\)/" PKGBUILD && \
	./gensrc.sh && \
	makepkg -Acsmf && \
	git commit -am "${TAG}" && \
	git push 
