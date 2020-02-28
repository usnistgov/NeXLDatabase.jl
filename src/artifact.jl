using Mmap

function write(db::SQLite.DB, filename::String, type::String, format::String)
    Mmap.mmap(filename) do data
        stmt1 = SQLite.Stmt(db, "INSERT INTO ARTIFACT ( TYPE, FORMAT, FILENAME, DATA) VALUES ( ?, ?, ?, ? );")
        results = DBInterface.execute(stmt1, (type, format, filename, data))
        return  DBInterface.lastrowid(results)
    end
end

function read
