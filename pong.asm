code segment

start:
	mov ax, seg top					; segment stosu
	mov ss, ax
	mov sp, offset top				; wierzcholek stosu
	mov ax, seg data				; segment danych
	mov ds, ax
	mov ax, 0a000h					; pamiec wideo
	mov es, ax

	mov dx, offset pomoc			; pomoc nt klawiszy
	call pisz
	
	call wczytajilu					; wczytuje, czy gra jeden czy dwoch graczy
	
	mov ax, 013h					; tryb graficzny 320x240, 256 kolorow
	int 10h

	call hlines
	call reset

	call readkey					; przed rozpoczeciem gry, coby nie wystraszyc gracza

mainloop:							; glowna petla programu
	call reset
	call sleep						; czeka 3 ms

	mov ah, 06h						; direct console input; no echo
	mov dl, 0ffh
	int 21h							; czy nacisnieto jakis klawisz
	
	cmp al, 'w'						; lewa paletka w gore
	je w
	cmp al, 's'						; lewa paletka w dol
	je s
	cmp al, 'i'						; prawa paletka w dol
	je i
	cmp al, 'k'						; prawa paletka w gore
	je k
	cmp al, 'p'						; pauza
	je p
	cmp al, 'x'						; wyjscie z programu
	je koniec
	
	mov byte ptr ds:[key], 0		; nic nie nacisnieto
	jmp mainloop					; nie nacisnieto zadnego poprawnego klawisza
	
w:									; obsluga klawisza w - lewy klawisz w gore
	mov ax, word ptr ds:[ly]		; zaladuj do ax wspolrzedna y paletki
	cmp ax, 6						; sprawdz, czy mozna ja przesunac do gory
	jle mainloop					; jesli nie, to nic nie rob
	sub ax, 5						; jesli tak, to przesun o 5 pikseli
	mov word ptr ds:[ly], ax		; wrzuc nowa wartosc do pamieci
	mov byte ptr ds:[key], 'w'
	jmp mainloop

s:									; obsluga klawisza s - lewy klawisz w dol
	mov ax, word ptr ds:[ly]		; ax = ly
	cmp ax, 140						; czy mozna przesunac w dol
	jge mainloop					; jesli nie, to nic nie rob
	add ax, 5						; jesli tak, to przesun
	mov word ptr ds:[ly], ax		; wrzuc do pamieci
	mov byte ptr ds:[key], 's'
	jmp mainloop
	
i:									; obsluga klawisza i - prawy klawisz w gore
	cmp byte ptr ds:[ilugraczy], 2	; jesli drugiego gracza obsluguje paletka, to nie mozna nim sterowac
	jne mainloop
	mov ax, word ptr ds:[py]
	cmp ax, 5
	jle mainloop
	sub ax, 5
	mov word ptr ds:[py], ax
	mov byte ptr ds:[key], 'i'
	jmp mainloop

k:
	cmp byte ptr ds:[ilugraczy], 2	; jw
	jne mainloop
	mov ax, word ptr ds:[py]		; obsluga klawisza k - prawy klawisz w dol
	cmp ax, 140
	jge mainloop
	add ax, 5
	mov word ptr ds:[py], ax
	mov byte ptr ds:[key], 'k'
	jmp mainloop
	
p:									; pauza - zamraza gre, dopoki uzytkownik nie wcisnie jakiegokolwiek klawisza
	mov bp, offset pauza			; na srodku ekranu piszemy szare P
	mov word ptr ds:[x], 145
	mov word ptr ds:[y], 80
	call clear
	call znak
	call copy
	call readkey
	jmp mainloop

punkt:								; rysuje punkt o wspolrzednych ds:[x], ds:[y]
	push cx
	mov ax, ds:[y]					; ktory wiersz
	mov cx, 320						; przechodzimy do ytego wiersza
	mul cx							; ax = (ds:[y])*320
	mov bx, ax						; bx = (ds:[y])*320
	mov ax, ds:[x]
	add bx, ax						; dodajemy do niego numer kolumny (bx = (ds:[y])*320+ds:[x]
	add bx, offset buf				; i adres bufora
	mov al, ds:[kol]				; kolor piksela
	mov ds:[bx], al					; wrzucamy do odpowiedniego miejsca w buforze
	pop cx
ret

reset:								; resetuje bufor, rysuje elementy gry i wyswietla je na ekranie (double-buffering)
	call clear						; wyczysc bufor
	call paletki					; narysuj paletki
	call vline						; i linie na srodku
	call wyniki						; punkty graczy
	call kulka						; i kulke
	call copy						; skopiuj na ekran
ret

kwadrat:							; rysuje kwadrat 6x6 px o wspolrzednych x, y
	push cx
	push word ptr ds:[y]
	push word ptr ds:[x]
	mov cx, 6						; 6 - wysokosc kwadratu
kwadloop0:
	push cx							; odkladamy zewnetrzny cx
	
	mov cx, 6						; szerokosc kwadratu, wewn. petla wykonuje sie tyle razy
kwadloop1:
	mov al, 15
	call punkt
	inc word ptr ds:[x]
	loop kwadloop1
	pop cx							; sciagamy zewnetrzny cx
	
	sub word ptr ds:[x], 6
	add word ptr ds:[y], 1
	
	loop kwadloop0
	pop word ptr ds:[x]
	pop word ptr ds:[y]
	pop cx
ret

hlines:								; rysuje dwie linie bezposrednio na ekranie
	mov al, byte ptr ds:[kol]		; ladujemy kolor
	
	mov di, 1924					; 6*320 + 4 - wspolrzedne pierwszego kwadratu
	call rysujlinie					; rysuje gorna linie

	mov di, 59524					; 186*320 + 4 - wspolrzedne pierwszej linii
	call rysujlinie					; rysuje dolna linie
ret
	
rysujlinie:							; rysuje linie i gory i dolu ekranu
	mov cx, 6						; kazda gruba linia sklada sie z 6ciu cienkich
rysujlinieloop:
	push cx							; zachowuje numer cienkiej lini

	mov cx, 312						; ilosc pikseli kazdej linii (320 - 2*4)
	rep stosb						; kopiuje ax (kolor) na ekran (es:di = ax)
	add di, 8						; omija prawy i lewy 'margines'
	pop cx							; odzyskuje licznik petli
	loop rysujlinieloop
ret

vline:								; rysuje przerywana biala pionowa linie w polowie ekranu
	mov cx, 15
	mov word ptr ds:[x], 157		; 157 = (320 / 2) - (6 / 2)
	mov word ptr ds:[y], 0
	mov byte ptr ds:[kol], 15		; linia jest biala
vlineloop:
	call kwadrat
	add word ptr ds:[y], 12			; kolejny kwadrat, miedzy nim a poprzednim przerwa
	loop vlineloop
ret

paletki:							; obsluga paletek - rysowanie, ew. automatyczne sterowanie prawa
	mov cx, 4						; paletka to 4 kwadraty
	mov ax, word ptr ds:[lx]		; najpierw bierzemy wspolrzedne lewej
	mov word ptr ds:[x], ax			; kopiujemy je przez rejestr do ds:[x], ds:[y]
	mov ax, word ptr ds:[ly]
	mov word ptr ds:[y], ax
	mov byte ptr ds:[kol], 15
lpaletka:
	call kwadrat					; rysujemy
	add word ptr ds:[y], 6			; kolejny kwadrat
	loop lpaletka

	cmp byte ptr ds:[ilugraczy], 1	; jesli gra dwoch graczy
	jne ppaletkarysuj				; to nie obslugujemy automatycznego sterowania paletka
	
	; jesli gra jeden i kulka sie zbliza, to komputer stara sie ja odbic
	cmp word ptr ds:[kierx], 0		; jesli kulka leci w lewo
	je ppaletkarysuj				; to prawa paletka nic nie robi
	cmp word ptr ds:[kx], 130		; jesli kulka jest jeszcze daleko
	jl ppaletkarysuj				; to tez nic nie rob
	mov ax, word ptr ds:[ky]		; sprawdzamy wspolrzedna pilki
	mov bx, word ptr ds:[py]		; wspolrzedna prawej paletki
	cmp ax, bx						; jesli pilka jest wyzej od paletki to jedziemy w jej strone
	jl pgora
	
	add bx, 22
	cmp ax, bx
	jg pdol							; jesli pilka jest nizej od paletki to jedziemy w jej strone
	jmp ppaletkarysuj
	
pgora:								; przesuniecie prawej paletki do gory - automatyczne sterowanie
	cmp word ptr ds:[py], 7			; jesli paletka jest u samej gory to nic nie rob
	jle ppaletkarysuj
	sub word ptr ds:[py], 6			; jesli nie jest, to przesun do gory
	mov byte ptr ds:[key], 'i'		; jesli gralby gracz, to klawiszem nacisnietym byloby i
	jmp ppaletkarysuj
	
pdol:								; przesuniecie prawej paletki w dol - automatyczne sterowanie
	cmp word ptr ds:[py], 140		; jeli paletka jest u samego dolu to nic nie rob
	jge ppaletkarysuj
	add word ptr ds:[py], 7
	mov byte ptr ds:[key], 'k'
	
ppaletkarysuj:						; rysuje prawa paletke
	mov cx, 4
	mov ax, word ptr ds:[px]		; bierzemy wspolrzedne prawej paletki
	mov word ptr ds:[x], ax			; kopiujemy
	mov ax, word ptr ds:[py]		; jw
	mov word ptr ds:[y], ax
	mov byte ptr ds:[kol], 15
ppaletka:
	call kwadrat					; rysujemy
	add word ptr ds:[y], 6			; kolejny kwadrat
	loop ppaletka
ret

kulka:								; obsluga kulki
	call przesunx
	mov ax, word ptr ds:[kx]		; x = przesuniete x kulki
	mov word ptr ds:[x], ax			; dla funkcji rysujacej kulke
	
	call przesuny
	mov ax, word ptr ds:[ky]		; y = przesuniete y kulki
	mov word ptr ds:[y], ax			; dla funkcji rysujacej
	
	call kwadrat					; rysujemy kulke
	
	cmp word ptr ds:[ky], 0			; jesli odbila sie od gornej linii to zmien skladowa y predkosci
	jle odbijy
	cmp word ptr ds:[ky], 163		; jw
	jge odbijy
	
	cmp word ptr ds:[kx], 10
	jle lewasciana					; paletka leci na lewa sciane, sprawdzamy czy trafila w paletke
	cmp word ptr ds:[kx], 304		; = 320 - 4 - 6 - 6
	jge prawasciana					; jw, prawa sciana
ret

przesunx:							
	cmp byte ptr ds:[kierx], 1		; kierx = 1 oznacza, ze kulka porusza sie w prawo
	je dodajx
odejmijx:
	sub word ptr ds:[kx], 5
ret
dodajx:
	add word ptr ds:[kx], 5
ret

przesuny:
	mov ax, word ptr ds:[vy]		; potrzebujemy predkosci w kierunku y
	cmp byte ptr ds:[kiery], 1		; jesli kierx = 1 to kulka leci w dol
	je dodajy
odejmijy:
	cmp word ptr ds:[ky], ax		; jesli jest u prawie samej gory, to przesuwamy ja na sama gore
	jle dozera
	sub word ptr ds:[ky], ax		; jesli nie, to zwyczajnie o 4 piksele
ret
dozera:
	mov word ptr ds:[ky], 0
ret
dodajy:
	add word ptr ds:[ky], ax		; zmieniamy ky o vy
ret

odbijy:								; odbija pilke od gornej lub dolnej linii
	xor byte ptr ds:[kiery], 1		; zmieniamy 1 na 0 lub 0 na 1
ret

prawasciana:						; pilka wpada na prawa sciane - sprawdzamy, czy trafia na paletke
	mov ax, word ptr ds:[py]		; poczatek paletki
	sub ax, 6						; wysokosc pilki
	cmp ax, word ptr ds:[ky]		; pilka trafila nad paletke
	jg wpadnijwprawasciane
	add ax, 30						; = 6+24
	cmp ax, word ptr ds:[ky]		; pilka trafila pod paletke
	jl wpadnijwprawasciane
	
	jmp odbijxprawa						; pilka trafila w paletke, zawraca

lewasciana:							; jw - lewa sciana
	mov ax, word ptr ds:[ly]
	sub ax, 6
	cmp ax, word ptr ds:[ky]
	jg wpadnijwlewasciane
	add ax, 30
	cmp ax, word ptr ds:[ky]
	jl wpadnijwlewasciane
	
	jmp odbijxlewa

odbijxlewa:							; odbija od lewej paletki
	cmp byte ptr ds:[key], 'w'		; jesli podczas zderzenia paletka ruszala sie w gore
	je palwgore
	cmp byte ptr ds:[key], 's'		; paletka poruszala sie w dol
	je palwdol
	jmp odbijx						; 'zawraca' kulke
	
odbijxprawa:						; odbija od prawej paletki
	cmp byte ptr ds:[key], 'i'
	je palwgore
	cmp byte ptr ds:[key], 'k'
	je palwdol

odbijx:
	xor byte ptr ds:[kierx], 1		; zamienia 0 na 1 lub 1 na 0
ret

palwgore:							; paletka ruszala sie w gore
	cmp byte ptr ds:[kiery], 1		; kulka w dol
	je zmniejszy					; zmniejszamy vy
	jmp zwiekszy					; jesli w tym samym kierunku, to zwiekszamy vy
	
palwdol:							; paletka ruszala sie w dol
	cmp byte ptr ds:[kiery], 0		; kulka w gore
	je zmniejszy
	jmp zwiekszy					; dla czytelnosci

zwiekszy:
	cmp byte ptr ds:[vy], 6			; jesli ma juz predkosc >= 6
	jge odbijx						; to nic nie rob
	inc byte ptr ds:[vy]			; a jesli nie, to zwieksz predkosc w kierunku y
	jmp odbijx

zmniejszy:
	cmp byte ptr ds:[vy], 3			; jw, predkosc musi byc > 1
	jle odbijx
	dec byte ptr ds:[vy]
	jmp odbijx

wpadnijwlewasciane:					; pilka wpadla w sciane, nie trafila w paletke
	inc word ptr ds:[ppunkty]		; zwiekszamy ilosc punktow gracza 2/komputera
	jmp wpadnijwsciane

wpadnijwprawasciane:				; jw
	inc word ptr ds:[lpunkty]		; zwiekszamy ilosc punktow gracza
	
wpadnijwsciane:						; kulka nie zostala odbita, resetujemy ustawienia kulki
	mov word ptr ds:[kx], 90
	mov word ptr ds:[ky], 70
	mov word ptr ds:[vx], 5
	mov word ptr ds:[vy], 4
	mov byte ptr ds:[kierx], 1
	mov byte ptr ds:[kiery], 1
	
	cmp word ptr ds:[lpunkty], 10	; gracz wygral
	je koniec
	cmp word ptr ds:[ppunkty], 10	; komputer wygral
	je koniec
	
	call reset						; gramy dalej
	call readkey
ret

readkey:							; czeka, az uzytkownik nacisnie klawisz
	mov ah, 08h
	int 21h
ret

wczytajilu:							; wczytuje ilosc graczy
	mov dx, offset ilumsg
	call pisz
	
	mov ah, 08h						; console input
	int 21h
	
	cmp al, '2'						; jesli uzytkownik zle podal
	jg wczytajilu
	cmp al, '1'
	jl wczytajilu
	
	sub al, '0'						; zmieniamy znak na liczbe
	mov byte ptr ds:[ilugraczy], al	; kopiujemy do pamieci ilosc 'ludzkich' graczy
ret

sleep:								; symuluje usypianie wykonujac 60000 pustych instrukcji
	mov cx, 60000
sleeploop:
	nop								; nie rob nic
	loop sleeploop
;	mov ah, 86h					; wait BIOS interrupt
;	mov cx, 30
;	mov dx, 3000					; 3 ms
;	int 15h
ret

clear:								; czysci obszar gry
	push es							; dla instrukcji rep stosb podstawimy ds za es
	mov ax, ds						; es = ds
	mov es, ax
	xor ax, ax						; wypelniamy zerami (czarnym)
	mov di, offset buf				; czysci caly bufor
	mov cx, 55680					; ilosc bajtow w buforze
	cld
	rep stosb						; es:[di] = al
	pop es
ret

wyniki:								; wyswietla cyfre z wynikiem
	mov word ptr ds:[x], 120		; pozycja punktow gracza
	mov word ptr ds:[y], 6
	
	mov ax, word ptr ds:[lpunkty]	; ile punktow ma gracz
	call cyfra
	
	mov word ptr ds:[x], 180		; pozycja punktow komputera na ekranie
	mov word ptr ds:[y], 6
	
	mov ax, word ptr ds:[ppunkty]	; ile punktow ma komputer
	call cyfra
ret

cyfra:								; funkcja rysujaca cyfry, na podstawie ax wyznacza adres cyfry w pamieci
	mov cx, 15						; kazda cyfra zajmuje 15 bajtow w pamieci
	mul cx							; ax *= 15
	mov bp, offset cyfry
	add bp, ax						; bp = ax*15 + offset cyfry
	
znak:								; rysuje jakikolwiek znak 3x5 'pikseli', o wsp. ds:[x], ds:[y], 'kod' znaku jest pod ds:[bp]
	mov cx, 5						; znak ma 5 wierszy
cyfraloop1:
	push cx
	mov cx, 3						; 3 kolumny
cyfraloop0:
	mov al, ds:[bp]					; bierzemy kolor z pamieci
	mov byte ptr ds:[kol], 0
	mov byte ptr ds:[kol], al		; ladujemy do ds:[kol], skad wezmie go punkt
	call kwadrat						; rysujemy kwadrat
	add word ptr ds:[x], 6			; przechodzimy o "piksel" dalej
	inc bp							; bierzemy nastepny "piksel" z pamieci
	loop cyfraloop0
	
	sub word ptr ds:[x], 18			; wracamy na lewa strone cyfry
	add word ptr ds:[y], 6			; i do nastepnej linijki

	pop cx
	loop cyfraloop1
	mov byte ptr ds:[kol], 15
ret

copy:								; kopiuje bufor do a000 (na ekran)
	mov si, offset buf				; kopiujemy bufor obszaru gry (ds+offset buf)
	mov di, 3840					; do tego obszaru (es:di), poczynajac od bajtu 3840
	mov cx, 55680					; ilosc pikseli w obszarze gry (miedzy liniami u gory i dolu)
	cld								; ustawia flage kierunku
	rep movsb						; kopiuje bajt po bajcie obszar
ret

pisz:
	mov ah, 09h
	int 21h
ret

koniec:								; piszemy kto wygral (albo nic, jesli nikt nie wygral) i wychodzimy z programu
	mov al, 03h						; powrot do trybu tekstowego
	mov ah, 0
	int 10h
	
	mov dx, offset newline
	cmp word ptr ds:[lpunkty], 10	; wygral lewy
	je lewywygral
	cmp word ptr ds:[ppunkty], 10
	jne wylacz						; nikt nie wygral, program zostal wczesniej wylaczony
	
	mov dx, offset prawywygralmsg
	jmp wylacz
	
lewywygral:
	mov dx, offset lewywygralmsg

wylacz:
	call pisz
	mov ah, 04ch					; wyjdz z programu
	int 21h
code ends

data segment
	cyfry	db 15, 15, 15,	15, 0, 15, 	15, 0, 15,	15, 0, 15,	15, 15, 15	; zero
			db 0, 15, 0,	15, 15, 0,	0, 15, 0,	0, 15, 0,	15, 15, 15	; jeden
			db 15, 15, 15,	0, 0, 15,	15, 15, 15,	15, 0, 0,	15, 15, 15	; dwa
			db 15, 15, 15, 	0, 0, 15,	15, 15, 15,	0, 0, 15,	15, 15, 15	; trzy
			db 15, 0, 15,	15, 0, 15,	15, 15, 15,	0, 0, 15,	0, 0, 15	; cztery
			db 15, 15, 15,	15, 0, 0,	15, 15, 15,	0, 0, 15,	15, 15, 15	; piec
			db 15, 15, 15,	15, 0, 0,	15, 15, 15,	15, 0, 15,	15, 15, 15	; szesc
			db 15, 15, 15,	0, 0, 15,	0, 0, 15,	0, 0, 15,	0, 0, 15	; siedem
			db 15, 15, 15,	15, 0, 15,	15, 15, 15,	15, 0, 15,	15, 15, 15	; osiem
			db 4, 4, 4,		4, 0, 4,	4, 4, 4,	0, 0, 4,	4, 4, 4		; dziewiec - czerwone
	pauza	db 8, 8, 8,		8, 0, 8,	8, 8, 8,	8, 0, 0,	8, 0, 0		; 'P' (pauza) ciemnoszare
	pomoc	db 'w - lewa paletka w gore, s - w dol, i - prawa w gore, k - prawa w dol', 10, 13
			db 'p - pauza, x - wyjscie z programu', 10, 13, '$'
	lewywygralmsg db 'Wygral gracz po lewej', 10, 13, '$'
	prawywygralmsg db 'Wygral gracz po prawej (komputer)', 10, 13, '$'
	ilumsg db 'Podaj ilosc graczy (1 - gra z komputerem, 2 - dwojka graczy)', 10, 13, '$'
	newline db 10, 13, '$'
	ilugraczy db ?					; ilu graczy uczestniczy
	key db 0						; ostatnio wcisniety klawisz
	x dw ?							; zmienne pomocnicze dla funkcji rysujacych
	y dw ?
	kx dw 90						; pozycja kulki
	ky dw 70
	vx dw 5							; predkosc kulki
	vy dw 4
	kierx db 1						; kierunek w ktorym porusza sie kulka
	kiery db 1
	lx dw 4							; pozycja lewej paletki
	ly dw 90
	px dw 310						; pozycja prawej paletki, 310 = 320 - 4 - 6
	py dw 80
	lpunkty dw 0					; ilosc punktow gracza
	ppunkty dw 0					; ilosc punktow komputera
	kol db 15						; kolor jakiego bedziemy uzywac (zwykle bialy)
	buf db 55680 dup(?)				; bufor ekranu, 55680 - ilosc pikseli miedzy liniami ogr. plansze (320 * 174)	
data ends

stack1 segment stack				; stos
	dw 200 dup(?)
	top dw ?
stack1 ends

end start
