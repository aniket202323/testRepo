CREATE PROCEDURE dbo.spEM_IEImportWasteEventType
@WasteTypeDesc  	 nVarChar(100),
@sReadOnly 	  	 nVarChar(100),
@UserId 	  	  	  	  	 Int 	 
AS
Declare @ReadOnly  	 int,
 	  	 @WasteTypeId 	 Int,
 	  	 @RC Int
SET @sReadOnly =  LTrim(RTrim(@sReadOnly))
SET @WasteTypeDesc =  LTrim(RTrim(@WasteTypeDesc))
IF @WasteTypeDesc = '' Set @WasteTypeDesc = Null
IF @sReadOnly = '' Set @sReadOnly = Null
 	  	 
If isnumeric(@sReadOnly) = 0  and @sReadOnly is not null
  Begin
 	 Select 'Failed - Read Only incorrect'
 	 Return(-100)
  End 
If @sReadOnly is null
 	 select @ReadOnly = 0
Else
 	 select @ReadOnly = Convert(Int,@sReadOnly)
IF @WasteTypeDesc Is Null
Begin
 	 Select 'Failed - Description is required'
 	 Return(-100)
End
SELECT @WasteTypeId = a.WET_Id 
 	 FROM Waste_Event_Type a
 	 WHERE a.WET_Name = @WasteTypeDesc
EXECUTE @RC = dbo.spEMSEC_PutWasteType @WasteTypeDesc, 	 @ReadOnly, 	 @UserId,@WasteTypeId  OUTPUT
If @WasteTypeId Is Null or @RC > 0
Begin
 	 Select 'Failed - Error Creating Waste Type'
 	 Return (-100)
End
