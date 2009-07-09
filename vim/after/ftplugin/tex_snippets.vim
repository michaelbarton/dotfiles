if !exists('loaded_snippet') || &cp
    finish
endif

let st = g:snip_start_tag
let et = g:snip_end_tag
let cd = g:snip_elem_delim

" Floats
exec "Snippet figure \\begin{figure}%{{{<CR>  \\centering<CR>  \\includegraphics*[width=10cm]{".st."file".et.".eps}<CR>  \\caption[".st."caption".et."]{".st."caption".et."}<CR>  \\label{figure:".st."label".et."}<CR>\\end{figure}%}}}<CR><CR>Figure\~\\ref{figure:".st."label".et."}<CR>".st.et

" Misc in-line text snippets
exec "Snippet cite \\cite{".st."ref".et."} ".st.et
exec "Snippet et \\emph{et. al} ".st.et
exec "Snippet emph \\emph{".st."emph".et."} ".st.et

" Section headings
exec "Snippet sec \\section{".st."name".et."}\\label{sec:".st."name:substitute(@z,'.','\\l&','g')".et."<CR>".st.et
exec "Snippet sub \\subsection{".st."name".et."}\\label{sub:".st."name:substitute(@z,'.','\\l&','g')".et."}<CR>".st.et
exec "Snippet ssub \\subsubsection{".st."name".et."}\\label{ssub:".st."name:substitute(@z,'.','\\l&','g')".et."}<CR>".st.et
