--            EXECUTE spDS_GetUdeStatuses 35,0
Create Procedure dbo.spDS_GetUdeStatuses
 @PUId int,
 @EventSubType int
AS
DECLARE  	  	  	    @NoStatus nVarChar(25)
DECLARE @DefaultStatus Int
 Select @NoStatus = '<None>'
--------------------------------------------------------
-- Event Status
--------------------------------------------------------
SELECT @DefaultStatus = a.Default_Event_Status
 	 FROM Event_Subtypes a
 	 WHERE a.Event_Subtype_Id = @EventSubType
SELECT @DefaultStatus = coalesce(@DefaultStatus,0)
DECLARE @Status Table (ProdStatus_Id int , ProdStatus_Desc nVarChar(50),LockData Int)
IF @DefaultStatus <> 0
BEGIN
 Insert Into @Status(ProdStatus_Id,ProdStatus_Desc,LockData)
  Select ProdStatus_Id, ProdStatus_Desc,coalesce(LockData,0)
   From Production_status a
   Join PrdExec_Status b on b.Valid_Status = a.ProdStatus_Id 
   WHERE b.PU_Id = @PUId
END
ELSE
BEGIN   
 	 Insert Into @Status (ProdStatus_Id,ProdStatus_Desc,LockData) Values (0,@NoStatus,0)
END
 Select ProdStatus_Id,ProdStatus_Desc,LockData From @Status Order by ProdStatus_Desc
SELECT DefaultStatus = @DefaultStatus
