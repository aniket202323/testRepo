 
 
/*	-------------------------------------------------------------------------------
	dbo.spLocal_MPWS_RETU_GetDispenseContainer
	
	Get Dispense Container info for return. 
	
	Date			Version		Build	Author  
	22-Jun-2016		001			001		Jim Cameron (GEIP)		Initial development	
 
test
 
DECLARE @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC dbo.spLocal_MPWS_RETU_GetDispenseContainer @ErrorCode output, @ErrorMessage output, 'DI905045973-14-10045237-001'
--EXEC dbo.spLocal_MPWS_RETU_GetDispenseContainer  '20151123145424-RM01-007'
 
SELECT @ErrorCode, @ErrorMessage
 
 
 
*/	-------------------------------------------------------------------------------
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_RETU_GetDispenseContainer]
	@ErrorCode			INT				OUTPUT,
	@ErrorMessage		VARCHAR(500)	OUTPUT,
	@DispenseContainer	VARCHAR(50)
 
AS
 
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
Create Table #OutputTable
(
Material varchar(25),
MaterialDesc nvarchar(255),
SAPLot varchar(25),
Location varchar(50),
[Status] varchar(50),
Quantity real,
MPWS_DISP_DISPENSE_UOM varchar(50),
QAStatus varchar(50),
DispenseEventId int,
RMCEventId int,
PUId int,
DefaultReturnLocation VARCHAR(100),
DefaultReturnLocationId int,
ErrorCode int,
ErrorMessage varchar(500)
)
	
BEGIN TRY
 
Insert into #OutputTable (Material,MaterialDesc,SAPLot,Location,[Status],Quantity,
							MPWS_DISP_DISPENSE_UOM,QAStatus,DispenseEventId,RMCEventId,PUId,
							DefaultReturnLocation)
	SELECT
		Material, -- varchar(25)
		MaterialDesc, -- nvarchar(255)
		t.Result SAPLot, -- Varchar_Value(varchar(25))
		ul.Location_Desc Location, -- varchar(50)
		[Status], -- varchar(50)
		Quantity, --real
		MPWS_DISP_DISPENSE_UOM UOM, --varchar(50)
		t2.Result,
		DispenseId,
		e.Event_Id,
		e.PU_Id,
		DefaultReturnLocation
	FROM (
			SELECT
				e.Event_Id DispenseId,
				pp.Process_Order PONum,
				p.Prod_Code Material,
				p.Prod_Desc MaterialDesc,
				ps.ProdStatus_Desc [Status],
				ed.Final_Dimension_X Quantity,
				SUBSTRING(CAST(peec.Value AS VARCHAR), 1, 100) DefaultReturnLocation,
				v.Test_Name,
				t.Result
 
			FROM dbo.Event_Details ed
				JOIN dbo.Events e ON ed.Event_Id = e.Event_Id
				JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id
				LEFT JOIN dbo.Tests t ON t.Result_On = e.[Timestamp]
					AND t.Var_Id = v.Var_Id
				LEFT JOIN dbo.Production_Status ps ON e.Event_Status = ps.ProdStatus_Id
				LEFT JOIN dbo.Products_Base p ON p.Prod_Id = e.Applied_Product
				LEFT JOIN dbo.Production_Plan pp ON ed.PP_Id = pp.PP_Id
				
				CROSS APPLY dbo.EquipmentClass_EquipmentObject eeo
				LEFT JOIN dbo.Property_Equipment_EquipmentClass peec ON eeo.EquipmentId = peec.EquipmentId
				LEFT JOIN dbo.PAEquipment_Aspect_SOAEquipment pas ON peec.EquipmentId = pas.Origin1EquipmentId
				LEFT JOIN dbo.Prod_Units_Base pu ON pu.PL_Id = pas.PL_Id
					AND pu.PU_Id = e.PU_Id
			WHERE v.Test_Name IN ('MPWS_DISP_DISPENSE_UOM', 'MPWS_DISP_BOMFIId')
				AND e.Event_Num = @DispenseContainer
				AND eeo.EquipmentClassName = 'Pre-Weigh - Area'
				AND peec.Name = 'Default Preweigh Return Location'
			) a
		PIVOT (MAX(Result) FOR Test_Name IN ([MPWS_DISP_DISPENSE_UOM], [MPWS_DISP_BOMFIId],[MPWS_INVN_QA_STATUS])) pvt
		JOIN dbo.Event_Components ec ON ec.Event_Id = DispenseId
		JOIN dbo.Events e ON e.Event_Id = ec.Source_Event_Id
		JOIN dbo.Variables_Base v ON v.PU_Id = e.PU_Id
		LEFT JOIN dbo.Tests t ON t.Result_On = e.[Timestamp]
			AND t.Var_Id = v.Var_Id
		JOIN dbo.Variables_Base v2 ON v2.PU_Id = e.PU_Id
		LEFT JOIN dbo.Tests t2 ON t2.Result_On = e.[Timestamp]
			AND t2.Var_Id = v2.Var_Id
		JOIN dbo.Event_Details ed ON e.Event_Id = ed.Event_Id
		JOIN dbo.Prod_Units_Base pu ON e.PU_Id = pu.PU_Id
		LEFT JOIN dbo.Unit_Locations ul ON ed.Location_Id = ul.Location_Id
			AND e.PU_Id = ul.PU_Id
	WHERE v.Test_Name = 'MPWS_INVN_SAP_LOT'	AND v2.Test_Name = 'MPWS_INVN_QA_STATUS'	
	------------------------------------------------------------------------------------------
	-- Add error code and error message as columns to the output
	------------------------------------------------------------------------------------------
	
	IF @@ROWCOUNT > 0
	BEGIN
		SET @ErrorCode = 1;
		SET @ErrorMessage = 'Success';		
		Update #OutputTable
		Set ErrorCode = @ErrorCode ,ErrorMessage = @ErrorMessage
	END
	ELSE
	BEGIN
		SET @ErrorCode = -1;
		SET @ErrorMessage = 'Container not found';
		Insert into #OutputTable
		(ErrorCode, ErrorMessage)values
		(@ErrorCode, @ErrorMessage)		
	END		
 
	------------------------------------------------------------------------------------------
	-- update default return location ID
	------------------------------------------------------------------------------------------
	UPDATE #OutputTable
	SET DefaultReturnLocationId = Location_Id
	FROM #OutputTable t
	JOIN	dbo.Unit_Locations ul ON ul.Location_Code = t.DefaultReturnLocation
			AND ul.PU_Id = t.PUId
	
 
	
--Update #OutputTable
--Set ErrorCode = @ErrorCode ,ErrorMessage = @ErrorMessage
	
	SELECT	Material ,
			MaterialDesc ,
			SAPLot ,
			Location ,
			[Status] ,
			Quantity ,
			MPWS_DISP_DISPENSE_UOM ,
			QAStatus ,
			DispenseEventId ,
			RMCEventId ,
			--PUId,    -- do not return in output
			DefaultReturnLocation ,
			DefaultReturnLocationId ,
			ErrorCode ,
			ErrorMessage 
	FROM #OutputTable
	
	Drop table #OutputTable
END TRY
BEGIN CATCH
 
	SET @ErrorCode = ERROR_NUMBER()
	SET @ErrorMessage = ERROR_MESSAGE()
	
END CATCH;
 
 
