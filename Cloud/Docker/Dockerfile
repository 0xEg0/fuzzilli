FROM swift:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=bash

RUN apt-get -y update
RUN apt-get -y upgrade

# Required for jsc
RUN apt-get install -y libicu-dev
RUN apt-get -y install nodejs npm

RUN mkdir /home/fuzzer
WORKDIR /home/fuzzer

# Add JavaScriptCore binary
ADD JSCBuilder/out jsc
# Add Spidermonkey binary
ADD SpidermonkeyBuilder/out spidermonkey
# Add v8 binary
ADD V8Builder/out v8
# Add duktape binary
ADD DuktapeBuilder/out duktape
# Add JerryScript binary
ADD JerryScriptBuilder/out jerryscript

# Add Corpus (if any)
ADD Corpus corpus

# Add Fuzzilli binaries
ADD FuzzilliBuilder/out/Fuzzilli Fuzzilli
ADD FuzzilliBuilder/out/REPRLRun REPRLRun
ADD FuzzilliBuilder/out/Fuzzilli_Fuzzilli.resources Fuzzilli_Fuzzilli.resources
ADD FuzzilliBuilder/out/package.json package.json

RUN npm install
RUN mkdir fuzz
