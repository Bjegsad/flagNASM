USE16 ;используем 16битные инструкции и адреса для представления данных
ORG 100h ;программа будет начинаться с адреса 100h

section .code: ;позволяет перемещаться между различными частями программы
		jmp start ;переход по метке start
		
section .data: ;предназначена для хранения данных, которые должны быть инициализированы при загрузке программы
		myfname db "Yuri $"
		mysname db "Chepurin $"

		messNA	db "Programm done$"
		messA	db "Here we go again$"

section .bss: ;для хранения неинициализированных переменных инициализируются нулями при запуске 
		int09h_vect	dw 0,0 ; вектор прерывания, который определяет адрес прерывания по нажатию клавиши
		lB		db 0,0 ;загрузка байта из памяти в регистр
		rB		db 0,0 ;}
	
section .code: ;сам код
	
	start:
		mov	al,3
		int	10h
		jmp	init

	new09h:     		;------------; новый обработчик прерывания INT-09h ----------------------------|
		pusha 		; сохранение регистров
		in al, 60h	; чтение скан-кода клавиатуры с входящего порта
		cmp al, 30h	; проверки на нужные клавиши
		je .fname
		cmp al, 1eh
		je .sname
		cmp al, 21h
		je .flag
		cmp al, 48h
		je .up
		cmp al, 4bh
		je .left
		cmp al, 50h
		je .down
		cmp al, 4dh
		je .right
		cmp al, 20h
		je .del
		popa 				; восстановление регистров
		jmp far [cs:int09h_vect]	; переход на старый обработчик
		
	.sys: ; восстановление работы с клавиатурой
		in al, 61h	; взять значениe порта управления клавиатурой
		mov ah, al	; сохранить его
		or al, 80h	; установить бит разрешения для клавиатуры
		out 61h, al	; и вывести его в управляющий порт
		xchg ah, al	; извлечь исходное значение порта
		out 61h, al	; и записать его обратно
		mov al, 20h	; послать сигнал "конец прерывания"
		out 20h, al	; контроллеру прерываний 8259
		ret
		
	.del: ; удаление резидентной программы
		popa
		;pushf
		;call far [cs:int09h_vect]
		call	near .sys
		mov	dx, [cs:int09h_vect]
		mov	ds, [cs:int09h_vect+2]
		mov	ax,2509h
		int	21h
		push cs
		pop ds
		mov ah, 49h
		int 21h
		int 20h
		
	.left: ; стрелка влево
		popa
		call near .sys
		mov al, 27
		mov ah, 0eh
		int 10h
		;mov ah, 0eh
		;mov dl, 27
		;int 10h
		iret

	.up: ; стрелка вверх
		popa
		call near .sys
		mov dl, 24
		mov ah, 02h
		int 21h
		iret

	.down: ; стрелка вниз
		popa
		call near .sys
		mov al, 25
		mov ah, 02h
		int 21h
		iret

	.right: ; стрелка вправо
		popa
		call near .sys
		mov dl, 26
		mov ah, 02h
		int 21h
		iret
	
	.fname: ; имя
		popa
		call near .sys
		push ds
		push cs
		pop ds
		mov ax, 0900h
		mov dx, myfname
		int 21h
		pop ds
		iret

	.sname: ; фамилия
		popa
		call near .sys
		push ds
		push cs
		pop ds
		mov ax, 0900h
		mov dx, mysname
		int 21h
		pop ds
		iret
	
	.flag: ; рисование флага
		mov ax, 000Eh
		int 10h
		mov bx, 0000
		mov ah, 0ch
		
		mov al, 07h
		mov dx, 0h
		mov cx, 0h
		;mov ax, 000E ; видео режим 640x200, 16 цветов ax = E
		;int 10 ; прерывание видео сервис
		;mov bx, 0000
		;mov ah, 0C ; рисования точки
		
	one: 
		int 10h
		inc cx
		cmp cx, 280h ; проверка правого края экрана
		jnz one ; возврат на 112
		mov cx, 0h
		inc dx ; инкремент DX
		cmp dx, 00C8h ; проверка нижнего края экрана
		jnz one
		
		mov al, 04h ; красный цвет
		mov dx, 19h ; верхний
		mov cx, 14h ; левый угол флага
		
	two: 
		int 10h ; прерывание видео сервис
		inc cx ; инкремент CX
		cmp cx, 26Ch ; проверка правого края флага
		jnz two ; возврат на 12D
		mov cx, 14h
		inc dx ; инкремент DX
		cmp dx, 4Bh ; проверка трети от всего размера флага
		jnz two
		
		mov al, 0Fh ; белый цвет
		mov dx, 4Bh ; на одну треть от верха
		mov cx, 14h ; левый угол флага
		
	three: 
		int 10h ; прерывание видео сервис
		inc cx ; инкремент CX
		cmp cx, 26Ch ; проверка правого края флага
		jnz three ; возврат на 147
		mov cx, 14h
		inc dx ; инкремент DX
		cmp dx, 7Dh ; проверка две трети от всего размера флага
		jnz three
		
		mov al, 0Ah ; зеленый цвет
		mov dx, 7Dh ; на две трети от верха
		mov cx, 14h ; левый угол флага
	four:
		int 10h ; прерывание видео сервис
		inc cx ; инкремент CX
		cmp cx, 26Ch ; проверка правого края флага
		jnz four  ; возврат на 161
		mov cx, 14h
		inc dx ; инкремент DX
		cmp dx, 00AFh ; проверка нижнего края флага
		jnz four
		
		mov cx, 0498h ; цикл для небольшой задержки
	timer1:	mov dx, 0498h
	timer2: dec dx
		cmp dx, 0
		jnz timer2
		loop timer1
		xor ah, ah
		mov ah, 00
		mov al, 03
		int 10h
		popa
		jmp far [cs:int09h_vect]

	init:              ;------------; устанавка нового обработчика ----------------------|
		push es
		mov ax, 3509h ; получение текущего обработчика
		int 21h
		mov [int09h_vect], bx
		mov [int09h_vect+2], es
		cmp bx, new09h
		jz already
		pop es
		push ds
		push cs
		pop ds
		mov   ax, 2509h		; меняем вектор 09h
		mov   dx, new09h	; на свой обработичик
		int   21h
		mov ah, 9
		mov dx, messNA
		int 21h
		pop ds
		mov   dx,init	; заносим адрес последней функции в DX
		int   27h	; выходим из программы, оставляя резидента в памяти


	already: ; если резидент уже загружен, будет выведенно сообщение
		mov ah, 9
		mov dx, messA
		int 21h
		mov ah, 0
		int 16h
		int 20h
		