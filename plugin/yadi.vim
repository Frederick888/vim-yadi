" yadi.vim - Yet Another Detect Indent
" Author:   Tim Schumacher <tim@tschumacher.net>
" License:  MIT
" Version:  1.0.0

if exists("g:loaded_yadi") || &compatible
    finish
endif
let g:loaded_yadi = 1
let s:yadi_ignore_after_trailing = get(g:, 'yadi_ignore_after_trailing', ['(', ',', '=', '->'])
let s:yadi_ignore_with_leading = get(g:, 'yadi_ignore_with_leading', ['.', '&', '|', '^', '+ ', '- ', '> ', '< ', '= '])

" With -bar these commands can be executed in a single line alongside other
" commands delimited by a | symbol.
command -bar DetectIndent call s:DetectIndent()
command -bar IndentTabs set noexpandtab shiftwidth=0 softtabstop=0
command -bar -nargs=* IndentSpaces call s:IndentSpaces(<f-args>)

function s:DetectIndent()
    let tabbed = 0
    let spaced = 0
    let indents = {}
    let lastwidth = 0
    let lines = getline(1, 1000) " Get the first 1000 lines
    for idx in range(len(lines))
        let line = lines[idx]
        let ignored = v:false
        if idx > 0
            for trailing in s:yadi_ignore_after_trailing
                if lines[idx - 1][-len(trailing):] == trailing
                    let ignored = v:true
                    break
                endif
            endfor
        endif
        if !ignored
            let trimmed = trim(line)
            for leading in s:yadi_ignore_with_leading
                if trimmed[:len(leading) - 1] == leading
                    let ignored = v:true
                    break
                endif
            endfor
        endif
        if line[0] == "\t"
            let tabbed += ignored ? 0 : 1
        else
            " The position of the first non-space character is the
            " indentation width.
            let width = match(line, "[^ ]")
            if width != -1
                if width > 0
                    let spaced += ignored ? 0 : 1
                endif
                let indent = width - lastwidth
                if !ignored && indent >= 2 " Minimum indentation is 2 spaces
                    let indents[indent] = get(indents, indent, 0) + 1
                endif
                let lastwidth = width
            endif
        endif
    endfor

    let total = 0
    let max = 0
    let winner = -1
    for [indent, n] in items(indents)
        let total += n
        if n > max
            let max = n
            let winner = indent
        endif
    endfor

    if tabbed > spaced*4 " Over 80% tabs
        set noexpandtab shiftwidth=0 softtabstop=0
    elseif spaced > tabbed*4 && max*5 > total*3
        " Detected over 80% spaces and the most common indentation level makes
        " up over 60% of all indentations in the file.
        set expandtab
        let &shiftwidth=winner
        let &softtabstop=winner
    endif
endfunction

function s:IndentSpaces(...)
    if a:0 >= 1 " Argument was passed
        " Vim converts the argument string to a number for the comparison.
        " Non-numbers get converted to 0 and also trigger the error message.
        if a:1 < 2
            echohl ErrorMsg
            echom "Argument to IndentSpaces must be a number greater than 1"
            echohl None
            return
        endif
        let indent = a:1
    else
        let indent = &tabstop
    endif

    set expandtab
    let &shiftwidth=indent
    let &softtabstop=indent
endfunction
