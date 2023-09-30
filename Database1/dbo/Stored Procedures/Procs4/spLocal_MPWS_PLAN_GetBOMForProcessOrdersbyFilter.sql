 
 
 
CREATE  PROCEDURE [dbo].[spLocal_MPWS_PLAN_GetBOMForProcessOrdersbyFilter]
		@PathId					INT=NULL,
		@PONumberMask			VARCHAR(8000)=NULL,
		@Stauts					VARCHAR(255)= NULL,--'Complete/Cancelled',
		@MaterialCode			VARCHAR(255)= NULL,--'RM02',
		@BOMItemStatusIdMask	VARCHAR(8000)	= NULL,
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(255)	OUTPUT
			 
AS	
-------------------------------------------------------------------------------
-- Get BOM info for passed in process orders
/*
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
EXEC spLocal_MPWS_PLAN_GetBOMForProcessOrdersbyFilter 29, null,null,'20160626093248609', null, @errorcode output, @errormessage output
 
EXEC spLocal_MPWS_PLAN_GetBOMForProcessOrders 29, 'PO14,PO12,PO11', '1'
*/
-- Date         Version Build Author  
-- 24-Sep-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
DECLARE @Flag int=0
DECLARE @SQL VARCHAR(1000)
 
SET NOCOUNT ON
 
CREATE	TABLE #tOutput
(
	PPId					INT									NULL,
	ProcessOrder			VARCHAR(25)							NULL,
	PPStatusId				INT									NULL,
	PPStatusDesc			VARCHAR(255)						NULL,
	BOMFIId					INT									NULL,
	BOMFormulationOrder		INT									NULL,
	ProdId					INT									NULL,
	ProdCode				VARCHAR(255)						NULL,
	ProdDesc				VARCHAR(255)						NULL,
	Quantity				FLOAT								NULL,
	UOM						VARCHAR(255)						NULL,
	BOMFIStatusId			INT									NULL,
	BOMFIStatusDesc			VARCHAR(255)						NULL,
	EngUnitId				INT									NULL
)
 
DECLARE  @tstatus TABLE (
 
Status_Desc			VARCHAR(70)							NULL
)
 
DECLARE  @tmaterial TABLE (
 
Prod_Desc			VARCHAR(70)							NULL
)
 
------------------------------------------------------------------------------
--  Get process orders for the passed in execution path and PO Mask
-------------------------------------------------------------------------------
INSERT	#tOutput(PPId, ProcessOrder, BOMFIId, BOMFormulationOrder, ProdId, 
		ProdCode, ProdDesc, Quantity, PPStatusId, PPStatusDesc, EngUnitId,
		BOMFIStatusId, BOMFIStatusDesc)
		SELECT	PP.PP_Id, PP.Process_Order, BOMFI.BOM_Formulation_Item_Id,
				BOMFI.BOM_Formulation_Order, BOMFI.Prod_Id, P.Prod_Code, P.Prod_Desc, 
				BOMFI.Quantity,PP.PP_Status_Id, PPS.PP_Status_Desc, BOMFI.Eng_Unit_Id,
				TFV.Value, PPS1.PP_Status_Desc
				FROM	dbo.Bill_Of_Material_Formulation_Item BOMFI		WITH (NOLOCK)
				JOIN	dbo.Production_Plan PP							WITH (NOLOCK)
				ON		PP.BOM_Formulation_Id		= BOMFI.BOM_Formulation_Id
				JOIN	dbo.Products_Base P									WITH (NOLOCK)
				ON		BOMFI.Prod_Id				= P.Prod_Id
				AND		PP.Path_Id					= @PathId
				JOIN	dbo.Production_Plan_Statuses PPS				WITH (NOLOCK)
				ON		PPS.PP_Status_Id			= PP.PP_Status_Id
				JOIN	dbo.Table_Fields_Values TFV		WITH (NOLOCK)
				ON		BOMFI.BOM_Formulation_Item_Id= TFV.KeyId
				AND		TFV.TableId					= 28
				JOIN	dbo.Production_Plan_Statuses PPS1				WITH (NOLOCK)
				ON		PPS1.PP_Status_Id			= TFV.Value
				ORDER
				BY		P.Prod_Code, PP.Process_Order
				
 
SET @SQL = 'SELECT * FROM #tOutput t'
 
IF LEN(@Stauts) > 0 AND @Stauts <> 'ALL'                                       
	BEGIN
    SET @SQL = @SQL + ' ' + 'where t.BOMFIStatusDesc = ' + '''' + @Stauts + ''''
    SET @flag = 1
END
 
IF LEN(@MaterialCode) > 0 AND @MaterialCode <> 'ALL'
BEGIN
    IF @flag = 1
    BEGIN
    SET @sql = @sql + ' and '
    END
    ELSE
    BEGIN
    SET @sql = @sql + ' where '
    END 
SET @sql = @sql + 't.ProdCode = ' + '''' + @MaterialCode + ''''
SET @flag = 1   
END 
 
 
EXECUTE(@SQL)       
 
-------------------------------------------------------------------------------
-- Insert A 'ALL'  dummy  record   
-------------------------------------------------------------------------------							
	
INSERT	@tstatus(Status_Desc) VALUES ('ALL')    
    
INSERT	@tstatus(Status_Desc)    
SELECT DISTINCT BOMFIStatusDesc  from #tOutput 
 
SELECT * FROM @tstatus
 
 
INSERT	@tmaterial(Prod_Desc) VALUES ('ALL')    
    
INSERT	@tmaterial(Prod_Desc) 
SELECT DISTINCT ProdDesc  from #tOutput 
 
SELECT * FROM @tmaterial
 
 
DROP TABLE #tOutput
 
 
--GRANT EXECUTE ON [dbo].[spLocal_MPWS_PLAN_GetBOMForProcessOrders] TO [public]
 
 
 
 
 
 
 
 
