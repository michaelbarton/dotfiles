set linebreak

iab ee \emph{et al.}
iab cc \cite{}<Left><Left>

" Insert figure
iab ff \begin{figure}%{{{<Enter>  \centering<Enter>  \includegraphics*[width=10cm]{dummy.eps}<Enter>  \caption[short caption]{long caption}<Enter>  \label{figure:label}<Enter>\end{figure}%}}}

" Insert figure with subfloats
iab ffsub \begin{figure}%{{{<Enter>  \centering<Enter>  \subfloat[caption]{<Enter>    \label{figure:label:a}<Enter>    \includegraphics*[width=6cm]{dummy.eps}<Enter>  }<Enter>  \hfill<Enter>  \subfloat[caption]{<Enter>    \label{figure:label:b}<Enter>    \includegraphics*[width=6cm]{dummy.eps}<Enter>  }<Enter>  \caption[short caption]{long caption}<Enter>  \label{figure:label}<Enter>\end{figure}%}}}<Enter>

" Insert tabular table
iab tt \begin{table}%{{{<Enter>  \centering<Enter>  \begin{tabular}{l r}<Enter>             \toprule<Enter>    X & X \\ \midrule<Enter>    X & X \\<Enter>    X & X \\<Enter>    X & X \\ \bottomrule<Enter>  \end{tabular}<Enter>  \caption[short caption]{long caption }<Enter>  \label{table:label}<Enter>\end{table}%}}}
