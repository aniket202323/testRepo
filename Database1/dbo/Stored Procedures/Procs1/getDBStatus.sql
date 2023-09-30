-- Batch submitted through debugger: SQLQuery4.sql|0|0|C:\Users\bhattacharya.ab.3\AppData\Local\Temp\32\~vs8049.sql
CREATE procedure getDBStatus
@DatabaseID int 
as
begin
declare @DBStatus varchar(20)
set @DBStatus=(select state_desc from sys.databases where database_id=@DatabaseID)
if @DBStatus='ONLINE'
--Print ' Database is ONLINE'
Print @DBStatus;
else
Print 'Database is in ERROR state.'
End

--drop proc SelectAllCustomers

--Exec getDBStatus 5