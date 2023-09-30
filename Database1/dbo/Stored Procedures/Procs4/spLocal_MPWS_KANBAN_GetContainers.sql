 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_KANBAN_GetAll
		
	This sp returns header info for spLocal_MPWS_KANBAN_GetContainers
	
	Date			Version		Build	Author  
	02-21-18		001			001		Don Reinert (GrayMatter)		Initial development	

test
  
*/	-------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[spLocal_MPWS_KANBAN_GetContainers]
	@Message VARCHAR(50) OUTPUT,
	@Container VARCHAR(25) OUTPUT,    --Events.Event_Num
	@Weight FLOAT OUTPUT,			--Event_Details.Final_Dimension_X
	@TareWeight VARCHAR(25) OUTPUT,  --Tests.Results for variable 'MPWS_DISP_TARE_QUANTITY'
	@UOM VARCHAR(25) OUTPUT,		--Tests.Results for 'MPWS_DISP_DISPENSE_UOM'
	@MaterialLotId VARCHAR(25) OUTPUT,		--Tests.Result for parent event for variable 'MPWS_INVN_SAP_LOT' -- Events.Source_Event
	@DispenseUser VARCHAR(25) OUTPUT,  --Events.User_Id
	@VerifyUser VARCHAR(25) OUTPUT,  --Events.Second_User_Id
	@Station VARCHAR(25) OUTPUT,		--Prod_Units_Base.PU_Desc
	@Scale VARCHAR(25) OUTPUT,     --Tests.Result for variable 'MPWS_DISP_SCALE'
	@Method VARCHAR(25) OUTPUT,     --Tests.Results for variable 'MPWS_DISP_DISPENSE_METHOD'
	@Time DATETIME OUTPUT,			--Events.Timestamp
	@Kanban VARCHAR(25)

AS

SET NOCOUNT ON;

DECLARE @Container_Local TABLE (
		ID						INT IDENTITY(1,1),
		PU_Id					INT,
		Event_Id				INT,
		Source_Event			INT,
		Container				VARCHAR(25) ,
		Weight					FLOAT ,
		TareWeight				VARCHAR(25) ,
		UOM						VARCHAR(25) ,
		MaterialLotId			VARCHAR(25) ,
		DispenseUser_Id			INT,
		DispenseUser			VARCHAR(30) ,
		VerifyUser_Id			INT,
		VerifyUser				VARCHAR(30) ,
		Station					VARCHAR(25) ,
		Scale					VARCHAR(25) ,
		Method					VARCHAR(25),
		Time					DATETIME
)

DECLARE
	@PU_Id INT,
	@ParentPU_Id INT,
	@KanPU_Id INT,
	--@TableFieldId INT,
	--@TableID INT,
	--@Value VARCHAR(25),
	--@IsKanban INT,
	--@RecordCount INT,
	@Event_Id INT,
	--@Timestamp DATETIME,
	@Var_Id INT,
	@CountId INT,
	@CurrentId INT,
	@Source_Event INT,
	@DispenseUser_Id INT,
	@VerifyUser_Id INT

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;

SELECT @KanPU_Id = PU_Id
	FROM Prod_Units_Base
	WHERE PU_Desc = @Kanban
IF (@KanPU_Id IS NULL)
	BEGIN
		SET @Message = 'Invalid Kanban'
	END
ELSE
	BEGIN
		INSERT INTO @Container_Local (pu_iD, Event_Id, Source_Event, Container, DispenseUser_Id, VerifyUser_Id, Time, Weight)
			SELECT e.PU_Id, e.Event_Id, ec.Source_Event_Id, e.Event_Num, e.User_Id, 
			e.Second_User_Id, e.TimeStamp, ed.Final_Dimension_X
			FROM dbo.Event_Details ed
				JOIN Event_Components ec ON ec.Event_Id = ed.Event_Id
				JOIN dbo.Events e ON ed.Event_Id = e.Event_Id
				JOIN dbo.Prod_Units_Base pu ON e.PU_Id = pu.PU_Id
				JOIN dbo.Prdexec_Paths pep ON pep.PL_Id = pu.PL_Id
				JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id
				LEFT JOIN dbo.Tests t ON t.Result_On = e.[Timestamp]
					AND t.Var_Id = v.Var_Id
				JOIN dbo.Products_Base p ON p.Prod_Id = e.Applied_Product
				JOIN dbo.Production_Plan pp ON ed.PP_Id = pp.PP_Id
			WHERE v.Test_Name = 'MPWS_DISP_KANBAN_LOC'
			  AND t.Result = @Kanban
		SELECT @CountId = MAX(ID) 
			FROM @Container_Local

		SELECT @CurrentId = 0
		WHILE (@CurrentId < @CountId)
		BEGIN
			SET @CurrentId = @CurrentId + 1
			SELECT @TareWeight = NULL, @MaterialLotId = NULL, @Scale = NULL, @Method = NULL, @UOM = NULL, @DispenseUser_Id = NULL, @VerifyUser_Id = NULL
		
			SELECT @PU_Id = PU_id, @Event_Id = Event_id, @Source_Event = Source_Event, @Container = Container, @DispenseUser_Id = DispenseUser_Id, @VerifyUser_Id = VerifyUser_Id
				FROM @Container_Local
				WHERE ID = @CurrentId
			SELECT @DispenseUser = Username
				FROM Users_Base
				WHERE User_Id = @DispenseUser_Id
			SELECT @VerifyUser_Id = Username
				FROM Users_Base
				WHERE User_Id = @VerifyUser_Id
			SELECT @Station = PU_Desc
				FROM Prod_Units_Base
				WHERE PU_Id = @PU_Id
			SELECT @Var_Id = Var_Id 
				FROM Variables_Base
				WHERE PU_ID = @PU_Id
				  AND Test_Name = 'MPWS_DISP_TARE_QUANTITY'
			SELECT @TareWeight = Result
				FROM Tests
				WHERE Var_Id = @Var_Id
				  AND Event_Id = @Event_Id
			SELECT @Var_Id = Var_Id 
				FROM Variables_Base
				WHERE PU_ID = @PU_Id
				  AND Test_Name = 'MPWS_DISP_SCALE'
			SELECT @Scale = Result
				FROM Tests
				WHERE Var_Id = @Var_Id
				  AND Event_Id = @Event_Id		
			SELECT @Var_Id = Var_Id 
				FROM Variables_Base
				WHERE PU_ID = @PU_Id
				  AND Test_Name = 'MPWS_DISP_DISPENSE_METHOD'
			SELECT @Method = Result
				FROM Tests
				WHERE Var_Id = @Var_Id
				  AND Event_Id = @Event_Id						  
			SELECT @Var_Id = Var_Id 
				FROM Variables_Base
				WHERE PU_ID = @PU_Id
				  AND Test_Name = 'MPWS_DISP_DISPENSE_UOM'
			SELECT @UOM = Result
				FROM Tests
				WHERE Var_Id = @Var_Id
				  AND Event_Id = @Event_Id						  
			SELECT @ParentPU_Id = PU_ID
				FROM Events 
				WHERE Event_Id = @Source_Event
			SELECT @Var_Id = Var_Id 
				FROM Variables_Base
				WHERE PU_ID = @ParentPU_Id
				  AND Test_Name = 'MPWS_INVN_SAP_LOT'
			SELECT @MaterialLotId = Result
				FROM Tests
				WHERE Var_Id = @Var_Id
				  AND Event_Id = @Source_Event									  								

			UPDATE @Container_Local SET Station = @Station,
									TareWeight = @TareWeight,
									Scale = @Scale, 
									Method = @Method, 
									MaterialLotId = @MaterialLotId,
									UOM = @UOM,
									DispenseUser = @DispenseUser,
									VerifyUser = @VerifyUser
				WHERE PU_Id = @PU_id
		end

END
SET	@Message = 'OK'

SELECT Container, Weight, TareWeight, UOM, MaterialLotId, DispenseUser, VerifyUser, Station, Scale, Method, Time 
	FROM @Container_Local




END





