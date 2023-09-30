CREATE PROCEDURE dbo.spSupport_CheckIdents   
AS
Declare
  @IdentityStatusBit int,
  @UserDefinedType varchar(1),
  @@TableName varchar(100)
Select @UserDefinedType = 'U'
Select @IdentityStatusBit = 7
Declare TBNs_Cursor INSENSITIVE CURSOR
  For (Select TableName = Object_Name(a.Id)
   	 From sys.syscolumns a
   	 Join sys.sysobjects b on b.Id = a.Id
   	 Where (b.Type = @UserDefinedType) And
        (a.Status & Power(2,@IdentityStatusBit)) != 0)
  For Read Only
  Open TBNs_Cursor  
Fetch_Loop:
  Fetch Next From TBNs_Cursor Into @@TableName
  If (@@Fetch_Status = 0)
    Begin
      DBCC CheckIdent (@@TableName)
      Goto Fetch_Loop
    End
Close TBNs_Cursor
Deallocate TBNs_Cursor
