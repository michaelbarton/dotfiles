setlocal foldmethod=expr
setlocal foldexpr=getline(v:lnum)[0]!='>'&&getline(v:lnum+1)[0]=='>'?'<1':1
