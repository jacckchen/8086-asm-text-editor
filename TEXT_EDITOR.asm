DATAS SEGMENT
    
    filename db 255,?,255 dup('$')
    fh dw ?
    row db 0
    col db 0
    lines db 0	;储存文件行数
    numbers db 255 dup(0)	;存储每行的字符数
    deta dw 0
    newline db 0dh,0ah,'$'
    newfile db 'create newfile.$'
    errorx db 'newfile error.$'
    errord db 'openfile error.$'
    errorinfo db 'open or create file error!The program will exit.$'
    deco1       db '  =================================================$'
    deco2       db '||            Command Line Text Editor             ||$'
    deco3       db '||    it will create file if it doesn''t exist     ||$'
    deco4       db '||         ESC = Exit || CTRL+S = Save File        ||$'
    deco5       db '||              ARROW KEYS = Navigate              ||$'
    deco6       db '  =================================================$'
    docPrompt   db 'Enter Document Name (.txt): $'
	buffer db 2000 dup(0)
    ;此处输入数据段代码  
DATAS ENDS

STACKS SEGMENT
    ;此处输入堆栈段代码
STACKS ENDS
;dh=row,dl=col,di=offset
Video_addr macro width,page_num
	push ax
	push dx
	mov al,width
	mul dh
	xor dh,dh
	add ax,dx
	shl ax,1
	add ax,page_num*100h
	mov di,ax
	pop dx
	pop ax
	endm
CODES SEGMENT
    ASSUME CS:CODES,DS:DATAS,SS:STACKS
START: 
main proc far
    MOV AX,DATAS
    MOV DS,AX
    
    
    mov ah,5
    mov row,ah
    mov al,12
    mov col,al
    call far ptr goto_pos 
    lea dx,deco1      ;decoration 1
    mov ah, 9
    int 21h
    inc row
    call far ptr goto_pos
    lea dx,deco2      ;decoration 2
    int 21h
    inc row
    call far ptr goto_pos
    lea dx,deco3      ;decoration 3
    int 21h
    inc row
    call far ptr goto_pos
    lea dx,deco4      ;decoration 4
    int 21h
    inc row
    call far ptr goto_pos
    lea dx,deco5      ;decoration 5
    int 21h
   	inc row
    call far ptr goto_pos
    lea dx,deco6      ;decoration 6
    int 21h
    mov al,13
    mov row,al
    call far ptr goto_pos
    lea dx,docPrompt  ;prompt doc name field
    int 21h
    
    ;读取文件路径
    lea dx,filename
    mov ah,0ah
    int 21h
    
    ;修正0dh的错误
    mov al,0
    mov bl,[filename+1]
    mov bh,0
    mov filename[bx+2],al
    
    ;尝试打开文件
    lea dx,filename[2]
    mov ah,3dh
    mov al,2
    int 21h
    ;如果没出现错误
    jnc next
    
    ;尝试新建文件
    mov ah,3ch
    mov cx,0
    int 21h
    jc error
    ;清除屏幕
    
    mov ah,3dh
    mov al,2
    int 21h
    ;jnc next2
next:
	;读取文件内容到缓冲区
	mov fh,ax
    mov bx,fh
    lea dx,buffer
    mov cx,1024
    mov ah,3fh
    int 21h
    jc error
    
    
    ;将文件内容输出到显存内
    mov ax,0b800h
    ;坐标数据清0
    mov row,al
    mov col,al
    mov bx,0
    mov es,ax
    mov di,0000h
    lea si,buffer
    call far ptr clearscreen
output:
	mov dl,byte ptr ds:[si]
	cmp dl,0
	jz endoutput
	
	;遇到回车的处理
	cmp dl,13d
	je CR
	
	mov byte ptr es:[di],dl
	inc si
	inc numbers[bx]
	add di,2
jmp output

CR:
	add si,2
	inc lines
	mov bl,lines
	inc row
	mov dl,0
	mov dh,row
	Video_addr 80,0
jmp output
endoutput:
	
	;初始化光标位置
	mov bh,0
	mov dx,0
	mov ah,2
	int 10h
	mov row,bh
	mov col,bh
MAIN_LOOP:
	mov ah,0
	int 16h
	cmp ah, 48h            ;if up arrow
    je UP
    cmp ah, 50h            ;if down arrow
    je DOWN
    cmp ah, 4Bh            ;if left arrow
    je LEFT
    cmp ah, 4Dh            ;if right arrow
    je RIGHT                             
	cmp ah,01h				;esc
	je exit
	cmp ah,0eh
	je delchar
	cmp ah, 1ch            ;if enter (newline) key
    je toENTER
    
	;看来，dos在发现键盘按下ctrl键时，并不会执行完16h的0号功能
	;而是与组合键一起发出一个设备控制字符后才接收该控制字符
	;cmp ah,1dh 
	;jne noctrl
	
	;mov ah,0
	;int 16h
	cmp al,19d
	je toSAVE
	
	
	push ax
	mov al,80
	mov dl,row
	mul dl
	shl ax,1
	mov cl,col
	mov ch,0
	shl cx,1
	add ax,cx
	mov di,ax
	pop ax
	mov ch,col
	mov bh,0
	mov bl,row
	;di->ah
	;al->di
	;ah->al
movback:
	mov ah,es:[di]
	mov es:[di],al
	;cmp ah,32d
	;je next5
	mov cl,8
	shr ax,cl
	add di,2
	inc ch
	cmp ch,numbers[bx]
	ja next5
jmp movback
next5:
	inc col
	;mov bh,0
	;mov bl,row
	inc numbers[bx]
	inc deta
	call far ptr goto_pos
jmp MAIN_LOOP
	
toENTER:
	inc lines
	mov dl,lines
	mov bl,row
	mov bh,0
	sub dl,bl
	inc bl
	mov al,numbers[bx]
	mov cl,8
	
incline:
	mov ah,numbers[bx+1]
	mov numbers[bx+1],al
	shr ax,cl
	inc bl
	dec dl
	jz nextinc
jmp incline
;将一行分为两行
nextinc:
	mov bh,0
	mov bl,row
	mov cl,col
 	mov dl,numbers[bx]
 	sub dl,cl
 	mov numbers[bx+1],dl
 	mov numbers[bx],cl
 	
 	
 	
 	;重新输出屏幕上的内容
 	mov cl,lines
 	mov dh,row
 	mov dl,0
 	sub cl,dh
 	mov ah,cl
incline2:
	inc dh
	;Video_addr改变了dh的内容，这花费我一晚上去寻找这个bug，这警戒我子程序一定要保存恢复好寄存器
	Video_addr 80,0
 	push di
 	dec cl
 	cmp cl,0ffh
 	je nono
jmp incline2

nono:
	pop di
incline3:	
	pop si
	push si
	mov cx,79d
copyline:
	mov dl,es:[si]
	mov es:[di],dl
	add di,2
	add si,2
loop copyline
	pop di
	dec ah
	cmp ah,0
	je nextinc2
jmp incline3
;将一行分为两行
nextinc2:
	mov dh,row
	mov dl,col
	mov cx,80
	sub cl,dl
	Video_addr 80,0
	mov si,di
	inc dh
	mov dl,0
	Video_addr 80,0
	mov dh,32d
copy2:
	mov dl,es:[si]
	mov es:[di],dl
	mov es:[si],dh
	add di,2
	add si,2
	
loop copy2
 	inc row
 	mov dl,0
 	mov col,dl
 	call far ptr goto_pos
   jmp MAIN_LOOP
    
    
    
UP:
    cmp row, 0
    je MAIN_LOOP
    mov bx,0
    mov bl,row
    mov cl,col
    cmp cl,numbers[bx]
    jne up2
    dec bl
    mov cl,numbers[bx]
    mov col,cl
up2:
    dec row
    call far ptr goto_pos 
    
    jmp MAIN_LOOP
	
DOWN:
	mov dl,lines
	cmp row,dl
	je MAIN_LOOP
	mov bx,0
    mov bl,row
    mov cl,col
    cmp cl,numbers[bx]
jne down2
    inc bl
    mov cl,numbers[bx]
    mov col,cl
down2:
	inc row
	call far ptr  goto_pos 
	jmp MAIN_LOOP
	
LEFT:
    cmp col,0
    je abnormall
    dec col
    call far ptr goto_pos 
abnormall:
    jmp MAIN_LOOP
    
RIGHT:
	mov bh,0
	mov bl,row
	mov cl,col
    cmp cl,numbers[bx]
    je abnormalr
    inc col
    call far ptr goto_pos
abnormalr:
    jmp MAIN_LOOP
    
delchar:
	mov dh,row
	mov dl,col
	cmp col,0
	je delline
	mov bx,0
	mov bl,row
	Video_addr 80,0
	mov cl,col
movfore:
	;mov al,es:[di+2]
	;mov es:[di],al
	;add di,2
	;mov al,es:[di]
	;cmp al,0
	;je next2
	mov al,es:[di]
	mov es:[di-2],al
	add di,2
	inc cl
	cmp cl,numbers[bx]
	ja next2
jmp movfore
next2:
	dec deta
	dec numbers[bx]
	dec col
	call far ptr goto_pos
	jmp MAIN_LOOP
delline:
	mov dl,lines
	mov bl,row
	sub dl,bl
	push dx
	jz next6
	mov bh,0
	mov ah,numbers[bx]
	mov cl,8
delnumbers:
	mov al,numbers[bx+1]
	shl ax,cl
	mov numbers[bx],ah
	inc bl
	dec dl
	jz next6
jmp delnumbers
next6:

	;删除屏幕内容
	pop ax
	cmp al,0
	;jz next7
	mov dh,row
	mov dl,0
delscr:
	Video_addr 80,0
	push di
	inc dh
	Video_addr 80,0
	mov si,di
	pop di
	mov cx,79d
copyline3:
	mov ah,es:[si]
	mov es:[di],ah
	add si,2
	add di,2
loop copyline3
	dec al
	cmp al,0ffh
	je next7
jmp delscr

next7:
	dec lines
	dec row
	call far ptr goto_pos
    jmp MAIN_LOOP
    
toSAVE:
	call far ptr SAVE
	jmp MAIN_LOOP
    
   
    jmp exit
error:
	mov ah,09h
	lea dx,errorinfo
	int 21h
exit:
    MOV AH,4CH
    INT 21H
main endp
CODES ENDS

code2 segment
	assume cs:code2,ds:DATAS
clearscreen proc far
	push ax
	push bx
	push cx
	push dx
	
	mov ah,6
	mov al,0
	mov bh,7
	mov ch,0
	mov cl,0
	mov dh,24
	mov dl,79
	int 10h
	
	pop dx
	pop cx
	pop bx
	pop ax
	
	retf
clearscreen endp

goto_pos proc far
	push ax
	push dx
	mov ah,02h
	mov dh,row
	mov dl,col
	int 10h
	pop dx
	pop ax
	retf
goto_pos endp

SAVE proc far
	;将指针移动至文件首
	mov cx,0
	mov row,cl
	mov col,cl
	mov dx,cx
	mov al,dl
	mov bx,fh
	mov ah,42h
	int 21h
	
	mov si,0
	mov di,0
	mov ax,0b800h
	mov es,ax
	mov bx,0
tobuffer:
	
	;cmp dl,0
	;je toCR
	mov cl,col
	cmp cl,numbers[bx]
	je toCR
	mov dl,es:[si]
	mov buffer[di],dl
	inc col
	inc di
	add si,2
	jmp tobuffer
toCR:
	dec lines
	cmp lines,0ffh
	je endwback
	inc bl
	xchg di,si
	inc row
	mov dh,row
	mov dl,0
	mov col,dl
	Video_addr 80,0
	xchg di,si
	
	;缓冲区写入回车CRLF
	mov dl,13d
	mov buffer[di],dl
	inc di
	mov dl,10d
	mov buffer[di],dl
	inc di
	
	;mov cl,lines
	;cmp cl,0
	;je next4
jmp tobuffer
;将最后一行写回缓冲区
;next4:
;	mov dl,es:[si]
;	cmp dl,32d
;	je endwback
;	mov buffer[di],dl
;	inc di
;	add si,2
;jmp next4
endwback:
	;inc di
	;mov cx,' '
	;mov buffer[di],cl
	mov dl,0
	mov buffer[di],dl
	
	mov cx,di
	;mov al,2
	;mov ah,42h
	;mov cx,0
	;mov dx,0
	;int 21h
	
	
	mov dx,deta
	cmp dx,0
jg no
	;mov cx,0ffffh
	;int 21h
	;mov ah,40h
	;mov cx,0
	;int 21h
	lea dx,filename[2]
    mov ah,3ch
    mov cx,0
    int 21h
    
jnc nextx
	push dx
	lea dx,errorx
	mov ah,09h
	int 21h
	pop dx
nextx:

    mov ah,3dh
    mov al,2
    int 21h
    mov fh,ax
    
jnc nextd
	push dx
	lea dx,errord
	mov ah,09h
	int 21h
	pop dx
nextd:

no:
	mov cx,di
	mov bx,fh
	lea dx,buffer
	mov ah,40h
	int 21h
	
	mov ah,3eh
	int 21h
	retf
SAVE endp
code2 ends

    END START
