function! psql#GetSystemCommand(user, password, host, database, port, command)
    let l:user = '-U' . a:user . ' '
    let l:password = 'PGPASSWORD=' . a:password . ' '
    let l:host = '-h ' . a:host . ' '
    let l:database = '-d '. a:database . ' '
    let l:port = '-p '. a:port . ' '

    let l:connection_details = l:password . 'psql ' . l:user . l:host . l:database . l:port . ' --pset footer'

    return 'echo ' . shellescape(join(split(a:command, "\n"))) . ' | ' . l:connection_details
endfunction

function! psql#GetQueryCommandFromCurrentConfig(command)
    let l:user = g:sqh_connections[g:sqh_connection]['user']
    let l:password = g:sqh_connections[g:sqh_connection]['password']
    let l:host = g:sqh_connections[g:sqh_connection]['host']
    let l:port = g:sqh_connections[g:sqh_connection]['port']
    let l:database = g:sqh_connections[g:sqh_connection]['database']

    return psql#GetSystemCommand(l:user, l:password, l:host, l:database, l:port, a:command)
endfunction

function! psql#GetResultsFromQuery(command)
    let l:system_command = psql#GetQueryCommandFromCurrentConfig(a:command)
    return system(l:system_command)
endfunction

function! psql#ShowDatabases()
    let db_query = 'SELECT datname FROM pg_database WHERE datistemplate = false;'
    call sqhell#InsertResultsToNewBuffer('SQHDatabase', psql#GetResultsFromQuery(db_query), 1)
endfunction

function! psql#ShowTablesForDatabase(database)
    let db_query = "SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname not in ('pg_catalog', 'information_schema');"
    call sqhell#InsertResultsToNewBuffer('SQHDatabase', psql#GetResultsFromQuery(db_query), 1)
endfunction

function! psql#SortResults(sort_options)
    let cursor_pos = getpos('.')
    let line_until_cursor = getline('.')[:cursor_pos[2]]
    let sort_column = len(substitute(line_until_cursor, '[^|]', '', 'g')) + 1
    exec '3,$!sort -k ' . sort_column . ' -t \| ' . a:sort_options
    call setpos('.', cursor_pos)
endfunction

function! psql#PostBufferFormat()
    keepjumps normal! ggdd

    " delete the last empty line
    if empty(getline('$'))
      keepjumps normal! Gddgg
    endif
endfunction

function! psql#GetTablesFromDatabaseQueryCommand(database) abort
  let query = "select tablename from pg_catalog.pg_tables where schemaname = 'public'"
  return psql#GetQueryCommandFromCurrentConfig(l:query)
endfunction
