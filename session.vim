let SessionLoad = 1
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/myprojects/searchpath
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
badd +1 main.lua
badd +3 scenes/automato/simulator.tl
badd +21 tlconfig.lua
badd +44 example.tl
badd +5 log.d.tl
badd +9 log.lua
badd +21 log.tl
badd +3 ansicolors.d.tl
badd +100 ansicolors.lua
badd +4 serpent.d.tl
badd +1 scenes/automato/simulator.lua
badd +3 conf.lua
badd +1 scenes/automato/cell-actions.lua
badd +6 scenes/automato/cell-actions.tl
badd +1 scenes/automato/grid.lua
badd +21 scenes/automato/simulator-thread.lua
badd +24 scenes/automato/simulator-thread.tl
badd +1 keyconfig.lua
badd +237 keyconfig.tl
badd +89 ./list.tl
badd +95 love.d.tl
badd +1 menu.lua
badd +745 ~/myprojects/snake2/main.lua
badd +7414 ~/projects/tl/tl.tl
badd +12 imgui.d.tl
badd +41 example.lua
badd +5 tools.tl
badd +55 celltool.tl
badd +181 ./scenes/automato/init.tl
badd +260 terraintool.lua
badd +3 scenes/automato/celltool.tl
argglobal
%argdel
$argadd main.lua
edit scenes/automato/simulator.tl
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=5
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 170 - ((19 * winheight(0) + 21) / 42)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
170
normal! 0
tabnext 1
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0&& getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 winminheight=1 winminwidth=1 shortmess=filnxtToOF
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &g:so = s:so_save | let &g:siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
