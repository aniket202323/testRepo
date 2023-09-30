CREATE FUNCTION [dbo].[fnRS_MakeOrderedResultSet](@InputString varchar(7000))
RETURNS @retTempTable TABLE (Id_Order Int, Id_Value Int)
AS
BEGIN
Declare @INstr VarChar(7999)
Declare @I int
Declare @Id int
Declare @T TABLE (Id_Order Int, Id_Value Int)
Select @I = 1
Select @INstr = @InputString + ','
While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
  Begin
 	 Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
    insert into @T (Id_Order, Id_Value) Values (@I,@Id)
    Select @I = @I + 1
 	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	 Select @INstr = Right(@INstr,Datalength(@INstr)-1)
  End
   -- copy to the result of the function the required columns
   INSERT @retTempTable
     Select Id_Order, Id_Value From @T
return
END
