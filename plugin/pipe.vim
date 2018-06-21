let s:status_map = [
  \"^Failed to compile.",
  \"^Compiled successfully!",
  \"^Compiled with warnings."
  \]

let s:eslint_pat = 'Line \(.*\):[ ]*\(.\+[^ ]\) \+ \([^ ]\+\)$'
func! s:parseline(filename, line)
  let s:eslint_info = matchlist(a:line, s:eslint_pat)

  if len(s:eslint_info) >=4
    let s:line_num = str2nr(s:eslint_info[1])
    let s:line_msg = s:eslint_info[2]
    let s:line_type = s:eslint_info[3]
    return {
          \'suc': 1,
          \'filename' :a:filename,
          \'lnum': s:line_num,
          \'text': s:line_msg ."  <".s:line_type.">"
          \}
  else
    return {'suc': 0}
  end
endf
func! s:getQuickfix(data)
  let s:errors = []
  let s:lines = split(a:data, "\n")
  let s:file = ""

  for s:line in s:lines
    if(s:line == "")
      let s:file = ""
    elseif(s:file == "")
      let s:file = s:line
    endif

    let s:error = s:parseline(s:file, s:line)
    if s:error.suc
      call add(s:errors, s:error)
    endif
  endfor
  return s:errors
endf



let s:ready_parse = 0
func! s:read_data(chan, data)
  if s:ready_parse
    let s:ready_parse = 0
    let s:quickfix_list = s:getQuickfix(a:data)
    call setqflist(s:quickfix_list, 'r')
    if g:complie_server_autoopen && len(s:quickfix_list) >= 1 
      exec g:complie_server_site. " cw"
    endif
  else
    for s:status in s:status_map
      if(a:data =~ s:status)
        let s:ready_parse = 1
        echo "Complie Server: ".s:status
        break
      endif
    endfor
  endif
endf

let g:complie_server_site = "bel"
let g:complie_server_autoopen = 1

if !exists("g:complie_server_cmd")
  let g:complie_server_cmd = "yarn start"
endif

func! s:stop_server()
  if exists('s:compile_job') && job_status(s:compile_job) == 'run'
    call job_stop(s:compile_job)
    echo "stop compile task!"
  endif
endf

func! s:start_server()
  if exists('s:compile_job') && job_status(s:compile_job) == 'run'
    call job_stop(s:compile_job)
    echo "restart compile task..."
  else
    echo "start compile task..."
  endif

  let s:compile_job_options = {
    \"mode": "raw",
    \"callback": function("s:read_data"),
    \"out_io": "pipe"
    \}
  let s:compile_job = job_start(g:complie_server_cmd, s:compile_job_options)
endf

command! StartServer call <SID>start_server()
command! StopServer call <SID>stop_server()
