CREATE procedure [dbo].[spSDK_AU_WasteType_Bak_177]
@AppUserId int,
@Id int OUTPUT,
@ReadOnly bit ,
@WasteType varchar(100) 
AS
DECLARE @ReturnCode 	  	  	 Int
If (@ReadOnly Is NULL)
 	 Select @ReadOnly = 0
 	 
EXECUTE @ReturnCode = spEMEC_UpdateWasteTypes @Id,@WasteType,@ReadOnly,@AppUserId
IF @ReturnCode > 0
BEGIN
 	 SELECT 'Add/Update failed'
 	 Return (-100)
END
Select @Id = WET_Id from Waste_Event_Type where WET_Name = @WasteType
If (@Id Is NULL)
 	 Begin
 	  	 SELECT 'Add/Update failed'
 	  	 Return (-100)
 	 End
RETURN(1)
