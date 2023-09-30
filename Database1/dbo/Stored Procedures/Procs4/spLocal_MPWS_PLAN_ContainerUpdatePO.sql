
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_PLAN_ContainerUpdatePO
		
	This sp returns header info for [spLocal_MPWS_PLAN_ContainerUpdatePO]
	
	Date			Version		Build	Author  
	02-19-2018		001			001		Andrew Drake (GrayMatter)		Initial development	

  
*/	-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_MPWS_PLAN_ContainerUpdatePO]
	@Message VARCHAR(50) OUTPUT,
	@Container VARCHAR(25),
	@Process_Order VARCHAR(25)
AS

SET NOCOUNT ON;

DECLARE @PU_Id INT,
		@Current_PP_Id INT,
		@Event_Id INT,
		@Result	VARCHAR(100),
		@User_Id VARCHAR(25)

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT @User_Id = User_Id
	FROM Users_Base 
	WHERE UserName = 'KanbanXface'

SELECT @Event_Id = e.Event_Id, @Current_PP_Id = ed.PP_Id, @PU_Id = e.PU_Id
	FROM dbo.Event_Details ed
		JOIN dbo.Events e ON ed.Event_Id = e.Event_Id
		JOIN dbo.Prod_Units_Base pu ON e.PU_Id = pu.PU_Id
		JOIN dbo.Prdexec_Paths pep ON pep.PL_Id = pu.PL_Id
		JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id
		LEFT JOIN dbo.Tests t ON t.Result_On = e.[Timestamp]
			AND t.Var_Id = v.Var_Id
		JOIN dbo.Products_Base p ON p.Prod_Id = e.Applied_Product
		JOIN dbo.Engineering_Unit eu ON eu.Eng_Unit_Desc = t.Result
		CROSS APPLY dbo.Engineering_Unit euKG	
	WHERE v.Test_Name = 'MPWS_DISP_DISPENSE_UOM'
		AND e.Event_Num = @Container

IF (@Current_PP_Id = NULL)
	BEGIN
		SET @Message = 'Invalid Container'
	END
ELSE
	BEGIN
		IF (@Current_PP_Id <> 'MISC' AND @Current_PP_Id <> 'ByWO')
			BEGIN
				SET @Message = 'Container already assigned to PO'
			END
		ELSE
			BEGIN
				EXECUTE @Result = dbo.spServer_DBMgrUpdEventDet
						@User_Id,  
						@Event_Id,
 						@PU_Id,
 						NULL, 	  				-- EventNum Not Used 11/20/02 
 						2,						-- 1 – Add, 2 – Update, 3 - Delete
						0,						-- 0 – Update fields that are not null to the new values.2 – Update all fields of Events to the values in Result Set. 
						NULL,					-- @AltEventNum output,
						NULL,					-- @Future2 output,
						NULL,					-- @DimX output,
						NULL,					-- @InitialDimY output,
						NULL,					-- @InitialDimZ output,
						NULL,					-- @InitialDimA output,
						NULL,					-- @FinalDimX output,
						NULL,					-- @FinalDimY output,
						NULL,					-- @FinalDimZ output,
						NULL,					-- @FinalDimA output,
						NULL,					-- @OrientationX output,
						NULL,					-- @OrientationY output,
						NULL,					-- @OrientationZ output,
						NULL,					-- @Future3 output,
						NULL,					-- @Future4 output,
						@Process_Order,			-- @OrderId output,
						NULL,					-- @OrderLineId output,
						NULL,					-- @PPId output,---------------------SCHEDULE PARAMETERS
						NULL,					-- @PPSetupDetailId output,----------SCHEDULE PARAMETERS
						NULL,					-- @ShipmentId output,
						NULL,					-- @CommentId output,
						NULL,					-- @EntryOn 
						NULL,					--@TimeStamp
						NULL,					--@Future6 output,
						NULL,					--@SignatureId
						NULL					--@productDefId
			END
	END

SET	@Message = 'OK'

END
