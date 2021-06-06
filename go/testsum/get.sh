#!/bin/sh

go get -u github.com/snksoft/crc

git config --global http.sslVerify false
go get -insecure -v -u go.cypherpunks.ru/gogost/v4/gost3410
go get -insecure -v -u go.cypherpunks.ru/gogost/v4/gost3413
go get -insecure -v -u go.cypherpunks.ru/gogost/v4/gost34112012256
go get -insecure -v -u go.cypherpunks.ru/gogost/v4/gost28147
go get -insecure -v -u go.cypherpunks.ru/gogost/v4/gost34112012512

