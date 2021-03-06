"#source /Users/michael/Library/Python/2.7/lib/python/site-packages/powerline/bindings/vim/plugin/powerline.vim
"set rtp+=/usr/local/lib/python2.7/site-packages/powerline/bindings/vim

if has("gui_running")
   let s:uname = system("uname")
   if s:uname == "Darwin\n"
      set guifont=Meslo\ LG\ S\ for\ Powerline
   endif
endif
"
let g:netrw_dirhistmax=0		" don't want .netrwhist history file
set printoptions=header:0		" don't print page headers0
set guifont=Inconsolata\ for\ Powerline:h15
let g:Powerline_symbols = 'fancy'
set encoding=utf-8
set t_Co=256					" enable 256-color mode
set fillchars+=stl:\ ,stlnc:\
set term=xterm-256color
set termencoding=utf-8
"
set laststatus=2				" last window always has a statusline
set number						" show line numbers
set tabstop=4					" tab spacing
"syntax enable
"set background=dark
"colorscheme solarized
set shiftwidth=4				" indent/outdent by 4 columns
set shiftround					" always indent/outdent to the nearest tabstop
"set expandtab					" use spaces instead of tabs
"set smarttab					" use tabs at the start of a line, spaces elsewhere
set viminfo=					" no logging of edit actions

au BufNewFile,BufRead *.gp,*.gnu,*.gnuplot*,.plt,*.gnuplot setf gnuplot

