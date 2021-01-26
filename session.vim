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
badd +36 scenes/automato/simulator.tl
badd +19 tlconfig.lua
badd +10 example.tl
badd +5 log.d.tl
badd +9 log.lua
badd +21 log.tl
badd +3 ansicolors.d.tl
badd +79 ansicolors.lua
badd +4 serpent.d.tl
badd +1 scenes/automato/simulator.lua
badd +18 conf.lua
badd +1 scenes/automato/cell-actions.lua
badd +86 scenes/automato/cell-actions.tl
badd +1 scenes/automato/grid.lua
badd +21 scenes/automato/simulator-thread.lua
badd +578 scenes/automato/simulator-thread.tl
badd +1 keyconfig.lua
badd +237 keyconfig.tl
badd +89 list.tl
badd +2257 love.d.tl
badd +1 menu.lua
badd +745 ~/myprojects/snake2/main.lua
badd +7437 ~/projects/tl/tl.tl
badd +14 imgui.d.tl
badd +41 example.lua
badd +5 tools.tl
badd +55 celltool.tl
badd +209 scenes/automato/init.tl
badd +260 terraintool.lua
badd +3 scenes/automato/celltool.tl
badd +26 scenes/automato/types.tl
badd +457 ~/.config/nvim/init.vim
badd +1 ~/projects/love-imgui/src/wrap_imgui_impl.h
badd +1122 ~/projects/love-imgui/src/imgui_iterator.h
badd +106 camera.lua
argglobal
%argdel
$argadd main.lua
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
enew
file \[BufExplorer]
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=5
setlocal fml=1
setlocal fdn=20
setlocal nofen
lcd ~/myprojects/searchpath
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
