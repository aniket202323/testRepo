/*
  Inserts or gets the id of an engine error code
*/
CREATE PROCEDURE dbo.spRS_AddEngineError
@Code_Desc varchar(50), 
@Code_Value varchar(10)
 AS
Declare @RowExists int
Select @RowExists = Code_Id
From Return_Error_Codes
Where Code_Value = @Code_Value
If @RowExists Is Null
  Begin -- This is a new entry
    Insert Into Return_Error_Codes(Code_Desc, Code_Value, App_Id, Group_Id)
    Values(@Code_Desc, @Code_Value, 11, 5)
    Return (0) -- New Row
  End
Else
  Begin     
    -- Return the existing row
    Return (1) -- Row Exists
  End
