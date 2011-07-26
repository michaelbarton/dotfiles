set expandtab
set autoindent
set shiftwidth=2
set softtabstop=2

set autowrite
set makeprg=ruby\ -rpp\ -ryaml\ -e\ 'pp\ YAML.load(File.read(ARGV.first))'\ %
