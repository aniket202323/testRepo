 
 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_GENL_GetRMCDetailsByFilter]
--	DeCLARE
		@status			VARCHAR(255)= NULL,--'Inventory',
		@location		VARCHAR(255)= NULL,--'PW01RecLoc01',
		@material		VARCHAR(255)= NULL,--'RM02',
		@RMCNumber		VARCHAR(255)= NULL,--'RMCIT-192',
		@startdate      DATETIME = NULL,
		@enddate		DATETIME = NULL
		
		
			
AS	
-------------------------------------------------------------------------------
-- Get locations associated with the passed in production unit
/*
exec  spLocal_MPWS_GENL_GetLocationsByProductionUnit 3379
exec  spLocal_MPWS_GENL_GetLocationsByProductionUnit 3379, 1
*/
-- Date         Version Build Author  
-- 14-Oct-2015  001     001   Alex Judkowicz (GEIP)  Initial development	
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
 
DECLARE @Flag int=0
DECLARE @SQL VARCHAR(1000)
 
SET NOCOUNT ON
 
 
 
 
CREATE	TABLE #tOutput			
(
	--Id						INT					IDENTITY(1,1)	NOT NULL,
	PUId					INT									NULL,
	PU_Desc					VARCHAR(70)						NULL,
	Event_Id				INT									NULL,
	Event_Num				VARCHAR(70)							NULL,
	Initial_Dimension_X		REAL								NULL,
	Final_Dimension_X		REAL								NULL,
	Initial_Dimension_A		REAL								NULL,
	Final_Dimension_A		REAL								NULL,
	Applied_Product			INT									NULL,
	prod_code				VARCHAR(70)							NULL,
	prod_desc_local			VARCHAR(70)							NULL,
	TimeStamp				DATETIME							NULL,
	Event_Status			INT									NULL,
	prodstatus_desc			VARCHAR(70)							NULL,
	Location_Id				INT									NULL,
	location_desc			VARCHAR(70)							NULL,
	QA						VARCHAR(25)							NULL,
	SAPLot					VARCHAR(25)							NULL,
	RecFlag					VARCHAR(25)							NULL,
	Alternate_Event_Num		VARCHAR(70)							NULL
	
)
 
DECLARE  @tstatus TABLE (
 
prodstatus_desc			VARCHAR(70)							NULL
)
 
DECLARE  @tlocation TABLE (
 
location_desc			VARCHAR(70)							NULL
)
 
DECLARE  @tmaterial TABLE (
 
prod_desc_local			VARCHAR(70)							NULL
)
 
 
				
				
 
INSERT	#tOutput	(PUId, PU_Desc, Event_Id,Event_Num,Initial_Dimension_X,Final_Dimension_X,Initial_Dimension_A,Final_Dimension_A,
                     Applied_Product,prod_code,prod_desc_local,TimeStamp,Event_Status,prodstatus_desc,Location_Id,
                     location_desc,QA,SAPLot,RecFlag,Alternate_Event_Num)
SELECT      EV.PU_Id, PU.PU_Desc, EV.Event_Id, EV.Event_Num, ED.Initial_Dimension_X, 
ED.Final_Dimension_X, ED.Initial_Dimension_A, ED.Final_Dimension_A,
EV.Applied_Product, p.prod_code, p.prod_desc, EV.TimeStamp,
EV.Event_Status, ps.prodstatus_desc, ED.Location_Id, ul.location_desc,t.Result as QA,te.Result as SAPLot,tes.Result as RecFlag,ED.Alternate_Event_Num
FROM	dbo.Events EV                                                   WITH (NOLOCK)
JOIN    dbo.Event_Details ED                    WITH (NOLOCK)
ON      EV.Event_Id= ED.Event_Id
JOIN    dbo.Prod_Units_Base PU                                         WITH (NOLOCK)
ON      EV.PU_Id = PU.PU_Id
join    dbo.Products_Base p
on      p.Prod_Id                   = ev.Applied_Product
join    dbo.Production_Status ps
on      ev.Event_Status             = PS.ProdStatus_Id
join    dbo.Unit_Locations ul
on      ul.Location_Id              = ED.Location_Id
join    dbo.variables_Base v
on      v.pu_id                     = pu.PU_Id and V.Test_Name  = 'MPWS_INVN_QA_STATUS'
join    dbo.Tests t                   
on      t.Var_Id                    = v.Var_Id		AND		T.Result_On   = EV.TimeStamp
join    dbo.variables_Base va
on      va.pu_id                    = pu.PU_Id and va.Test_Name   = 'MPWS_INVN_SAP_LOT'
join    dbo.Tests te                   
on      te.Var_Id                   = va.Var_Id		AND		TE.Result_On    = EV.TimeStamp
join    dbo.variables_Base vari
on      vari.pu_id                  = pu.PU_Id and vari.Test_Name    = 'MPWS_INVN_REC_FLAG'
join    dbo.Tests tes                   
on      tes.Var_Id                  = vari.Var_Id	AND		TES.Result_On = EV.TimeStamp   
 
  
 
 
--select * from #tOutput
 
 
 
 
 
 
 
------------------------------------------------------------------
SET @SQL = 'SELECT * FROM #tOutput t'
 
IF LEN(@status) > 0 OR @status <> 'ALL'                                       
	BEGIN
    SET @SQL = @SQL + ' ' + 'where t.prodstatus_desc = ' + '''' + @status + ''''
    SET @flag = 1
END
                
--IF LEN(@location) > 0
IF LEN(@location) > 0 OR @location <> 'ALL'
BEGIN
	IF @flag = 1
	BEGIN
    SET @SQL = @SQL + ' and '
    END
    ELSE
    BEGIN
    SET @SQL = @SQL + ' where '
    END
SET @SQL = @SQL + 't.location_desc = ' + '''' + @location + ''''
SET @flag = 1   
END       
                 
IF LEN(@material) > 0 OR @material <> 'ALL'
BEGIN
    IF @flag = 1
    BEGIN
    SET @sql = @sql + ' and '
    END
    ELSE
    BEGIN
    SET @sql = @sql + ' where '
    END 
SET @sql = @sql + 't.prod_desc_local = ' + '''' + @material + ''''
SET @flag = 1   
END 
                 
IF LEN(@RMCNumber) > 0
BEGIN
	IF @flag = 1
    BEGIN
    SET @sql = @sql + ' and '
    END
    ELSE
    BEGIN
    SET @sql = @sql + ' where '
    END 
SET @sql = @sql + 't.event_num = ' + '''' + @RMCNumber + ''''
SET @flag = 1   
END 
                 
IF LEN(@startdate) > 0
BEGIN
	IF @flag = 1
    BEGIN
    SET @sql = @sql + ' and '
    END
    ELSE
    BEGIN
    SET @sql = @sql + ' where '
    END 
SET @sql = @sql + 't.timestamp >= ' + '''' + CONVERT(VARCHAR(19),@startdate,120) + ''''
SET @flag = 1   
END    
                 
                 
IF LEN(@enddate) > 0
BEGIN
	IF @flag = 1
	BEGIN
    SET @sql = @sql + ' and '
    END
    ELSE
    BEGIN
    SET @sql = @sql + ' where '
    END 
SET @sql = @sql + 't.timestamp <= ' + '''' + CONVERT(VARCHAR(19),@enddate,120) + ''''
SET @flag = 1   
END                      
              
  
        
                         
      --select  @SQL                                                                                                  
EXECUTE(@SQL)       
 
-------------------------------------------------------------------------------
-- Insert A 'ALL'  dummy  record   
-------------------------------------------------------------------------------							
	
INSERT	@tstatus(prodstatus_desc) VALUES ('ALL')    
    
INSERT	@tstatus(prodstatus_desc)    
SELECT DISTINCT prodstatus_desc  from #tOutput 
 
SELECT * FROM @tstatus
 
 
 
 
INSERT	@tlocation(location_desc) VALUES ('ALL')    
    
INSERT	@tlocation(location_desc) 
SELECT DISTINCT location_desc  from #tOutput 
 
SELECT * FROM @tlocation
 
 
 
INSERT	@tmaterial(prod_desc_local) VALUES ('ALL')    
    
INSERT	@tmaterial(prod_desc_local) 
SELECT DISTINCT prod_desc_local  from #tOutput 
 
SELECT * FROM @tmaterial
ORDER BY prod_desc_local
 
DROP TABLE #tOutput
                            
--    GRANT EXECUTE ON [dbo].[spLocal_MPWS_GENL_GetRMCDetailsByFilter] TO [public]                                                                            
