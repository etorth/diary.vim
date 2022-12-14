if !has('python3')
    echohl ErrorMsg | echomsg 'PyGithubDiary: python3 is required but not available' | echohl None
    finish
endif


function! s:Diary_echoError(msg)
    if type(a:msg) == v:t_string
        echohl ErrorMsg | echomsg 'PyGithubDiary: ' . a:msg | echohl None
    else
        echohl ErrorMsg | echomsg 'PyGithubDiary: ' . string(a:msg) | echohl None
    endif
endfunction


function! s:Diary_createDiaryInst()
    " disable this check because of pynvim bug
    "
    "     https://github.com/neovim/pynvim/pull/496
    "
    " till now the fix has not been enabled

    " if py3eval('"PyGithubDiary_testString"') != 'PyGithubDiary_testString'
    "     call s:Diary_echoError('python interpreter does not work')
    "     return v:false
    " endif

python3 << PY3_EOF

import os
import PyGithubDiary

try:
    if 'g_diaryInst' not in locals():
        try:
            homeDir = os.environ['HOME']
        except KeyError:
            homeDir = os.environ['HomePath']
        except:
            raise RuntimeError('No valid home path configured in os envs')

        jsonPath = homeDir + '/.diary.json'
        if not os.path.isfile(jsonPath):
            raise RuntimeError('Config file does not exist: %s' % jsonPath)

        g_diaryInst = PyGithubDiary.Diary(jsonPath)

except Exception as e:
    g_diaryInstError = str(e)

else:
    g_diaryInstError = None

PY3_EOF

    let l:err = py3eval('g_diaryInstError')
    if l:err == v:null
        return v:true
    else
        call s:Diary_echoError(l:err)
        return v:false
    endif
endfunction


function! s:DiaryFunc_openComplete(A, L, P)
    if !s:Diary_createDiaryInst()
        return
    endif

    let l:res = printf('g_diaryInst.export_listDiaries("%s", "%s", "%s")', a:A, a:L, a:P)->py3eval()
    if !l:res[0]
        call s:Diary_echoError(l:res[1])
        return
    endif

    return l:res[1]
endfunction


function! s:DiaryFunc_open(filename, newmode)
    if !s:Diary_createDiaryInst()
        return
    endif

    " vim tab does not have name
    " there is not a good way to detect if a diary is already open

    redir => l:tabs_out
    silent tabs
    redir END

    let l:tabs_out = split(l:tabs_out, '\n')
    let l:tabs_len = len(l:tabs_out)
    let l:tabs_map = {}

    let l:c = 0
    while l:c < l:tabs_len
        if trim(l:tabs_out[l:c]) =~ '^Tab page \d\+$'
            let l:tabs_map[trim(l:tabs_out[l:c + 1][3:])] = matchstr(l:tabs_out[l:c], '\d\+')
        endif
        let l:c += 1
    endwhile

    if has_key(l:tabs_map, a:filename)
        call execute('tabnext ' . l:tabs_map[a:filename])
        call s:Diary_echoError(printf('diary %s has already been opened', a:filename))
        return
    endif

    let l:res = printf('g_diaryInst.export_getContent("%s", newmode=%s)', a:filename, a:newmode ? 'True' : 'False')->py3eval()
    if !l:res[0]
        call s:Diary_echoError(l:res[1])
        return
    endif

    call execute('tabnew ' . a:filename)
    norm gg

    put! =l:res[1]

    norm G
    let t:PyGithubDiary_tab_opened = 1
endfunction


function! s:DiaryFunc_submit()
    if !exists('t:PyGithubDiary_tab_opened')
        call s:Diary_echoError('current tab is not opened to submit diary')
        return
    endif

    if wordcount()['bytes'] >= 100 * 1024 * 1024
        call s:Diary_echoError('can not submit file size greater than 100 mbytes')
        return
    endif

    let l:res = printf('g_diaryInst.export_submitContent(%s%s%s, filename="%s")', '"""', substitute(join(getline(1, '$'), '\n'), '"', '\\"', 'g'), '"""', bufname())->py3eval()
    if !l:res[0]
        call s:Diary_echoError(l:res[1])
        return
    endif

    unlet t:PyGithubDiary_tab_opened
    q!
endfunction


function! s:DiaryFunc_viewText(regfile)
    if !s:Diary_createDiaryInst()
        return
    endif

    tabnew
    norm gg

    let l:res = printf('g_diaryInst.export_viewText(%s%s%s)', '"""', a:regfile, '"""')->py3eval()
    if !l:res[0]
        call s:Diary_echoError(l:res[1])
        return
    endif

    put! =l:res[1]
    norm gg
endfunction


function! s:DiaryFunc_viewHtml(regfile)
    if !s:Diary_createDiaryInst()
        return
    endif

    tabnew
    norm gg

    let l:res = printf('g_diaryInst.export_viewHtml(%s%s%s)', '"""', a:regfile, '"""')->py3eval()
    if !l:res[0]
        call s:Diary_echoError(l:res[1])
        return
    endif

    put! =l:res[1]
    norm gg

    set filetype=html
endfunction


command! DiaryNew :call s:DiaryFunc_open(strftime('%Y.%m.%d.txt'), v:true)
command! -nargs=1 -complete=customlist,s:DiaryFunc_openComplete DiaryOpen :call s:DiaryFunc_open(<q-args>, v:false)

command! DiarySubmit :call s:DiaryFunc_submit()

command! -nargs=1 DiaryViewText :call s:DiaryFunc_viewText(<q-args>)
command! -nargs=1 DiaryViewHtml :call s:DiaryFunc_viewHtml(<q-args>)
