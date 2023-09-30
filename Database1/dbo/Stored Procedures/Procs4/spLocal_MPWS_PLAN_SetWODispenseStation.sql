 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_PLAN_GetWorkOrder
		
	This sp returns header info for spLocal_MPWS_PLAN_SetWODispenseStation
	
	Date			Version		Build	Author  
	02-10-18		001			001		Andrew Drake (GrayMatter)		Initial development	

test
  
*/	-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_MPWS_PLAN_SetWODispenseStation]
	@Message VARCHAR(50) OUTPUT,
	@WorkOrder VARCHAR(25),
	@DispenseStation VARCHAR(25)

AS

SET NOCOUNT ON;

DECLARE
	@PU_Id INT,
	@TableFieldId INT,
	@TableID INT,
	@Value VARCHAR(25),
	@Event_Id INT,
	@Var_Id INT

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT @PU_Id = PU_Id
		FROM Prod_Units_Base
		WHERE Prod_Units_Base.PU_Desc = 'KB-WO'
	
	SELECT @Event_Id = Event_Id
		FROM Events
		WHERE Events.PU_Id = @PU_Id
		  AND Events.Event_Num = @WorkOrder
				  

	IF (@DispenseStation = '0' OR @DispenseStation = NULL OR @DispenseStation = '')
		-- UPDATE DISPENSED STATION TO NOTHING
		BEGIN
			SELECT @Var_Id = Var_Id FROM Variables_Base WHERE PU_ID = @PU_Id AND Var_Desc = 'DispenseStation'							
			UPDATE Tests SET Result = '' WHERE Var_Id = @Var_Id AND Event_Id = @Event_Id
			SET	@Message = 'OK'
		END
	ELSE 
		-- UPDATE DISPENSED STATION
		BEGIN
			SELECT @Var_Id = Var_Id FROM Variables_Base WHERE PU_ID = @PU_Id AND Var_Desc = 'DispenseStation'							
			UPDATE Tests SET Result = @DispenseStation	WHERE Var_Id = @Var_Id AND Event_Id = @Event_Id
			SET	@Message = 'OK'
		END

	Select @Message AS Message

END

