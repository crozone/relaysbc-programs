

HTDOCS = index.html history.html relays.html circuits.html cond.html \
arch.html iset.html example-code.html usage.html semi.html tools.html serial.html

GIFS = alubit.gif alwaysclosed.gif block.gif compl.gif condcircuit.gif \
condlogic.gif condtable.gif edge.gif halfadd.gif halfdriver.gif inc.gif \
insn.gif latch.gif mslave.gif openlogic.gif phys.gif relay.gif rmslave.gif \
rmslave1.gif singleended.gif tlatch.gif wiredor.gif xorgate.gif relaylarge.jpg \
relaysmall1.jpg putty-setup.gif putty-setup1.gif leds.gif devicemanager.gif \
tip.gif ftdi.gif prolific.gif


all : ${HTDOCS}

publish : ${HTDOCS} ${GIFS}
	scp ${HTDOCS} ${GIFS} jhallen,relaysbc@web.sourceforge.net:htdocs

clean :
	/bin/rm -f ${HTDOCS}

index.html : header-src.html index-src.html footer-src.html
	sed "s,@title@,Relay Trainer," <header-src.html | cat - index-src.html footer-src.html > $@

history.html : header-src.html history-src.html footer-src.html
	sed "s,@title@,History of Relay Computers," <header-src.html | cat - history-src.html footer-src.html > $@

relays.html : header-src.html relays-src.html footer-src.html
	sed "s,@title@,Information about Relays," <header-src.html | cat - relays-src.html footer-src.html > $@

circuits.html : header-src.html circuits-src.html footer-src.html
	sed "s,@title@,Relay Circuit Design," <header-src.html | cat - circuits-src.html footer-src.html > $@

cond.html : header-src.html cond-src.html footer-src.html
	sed "s,@title@,Condition Logic," <header-src.html | cat - cond-src.html footer-src.html > $@

arch.html : header-src.html arch-src.html footer-src.html
	sed "s,@title@,Architecture," <header-src.html | cat - arch-src.html footer-src.html > $@

iset.html : header-src.html iset-src.html footer-src.html
	sed "s,@title@,Instruction Set," <header-src.html | cat - iset-src.html footer-src.html > $@

example-code.html : header-src.html example-code-src.html footer-src.html
	sed "s,@title@,Example Code," <header-src.html | cat - example-code-src.html footer-src.html > $@

usage.html : header-src.html usage-src.html footer-src.html
	sed "s,@title@,Front Panel Usage Guide," <header-src.html | cat - usage-src.html footer-src.html > $@

semi.html : header-src.html semi-src.html footer-src.html
	sed "s,@title@,Semiconductor Design," <header-src.html | cat - semi-src.html footer-src.html > $@

tools.html : header-src.html tools-src.html footer-src.html
	sed "s,@title@,Software Tools," <header-src.html | cat - tools-src.html footer-src.html > $@

serial.html : header-src.html serial-src.html footer-src.html
	sed "s,@title@,Serial Console," <header-src.html | cat - serial-src.html footer-src.html > $@
