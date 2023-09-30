/*
==== TESTING ====
Declare @o varchar(8000)
exec spRS_MakeStringFromQueryResults 'SELECT PROD_ID FROM PRODUCTS', @o output
select @o
*/
CREATE PROCEDURE dbo.spRS_MakeStringFromQueryResults
@InputQuery varchar(1000),
@OutputString varchar(8000) output
AS
Create Table #LocalTempTable(Id int)
Insert Into #LocalTempTable Exec (@InputQuery)
Declare @MyId int
Declare MyCursor INSENSITIVE CURSOR
  For (
       Select Id From #LocalTempTable
      )
  For Read Only
  Open MyCursor  
Select @OutputString = ''
MyLoop1:
  Fetch Next From MyCursor Into @MyId 
  If (@@Fetch_Status = 0)
    Begin
 	  	 If Len(@OutputString) = 0
 	  	  	 Select @OutputString = @OutputString + convert(VarChar(5), @MyID)
 	  	 Else
 	  	  	 Select @OutputString = @OutputString + ',' + convert(VarChar(5), @MyID)
 	  	 Goto MyLoop1
    End 
    goto myEnd
myEnd:
Close MyCursor
Deallocate MyCursor
Drop Table #LocalTempTable
