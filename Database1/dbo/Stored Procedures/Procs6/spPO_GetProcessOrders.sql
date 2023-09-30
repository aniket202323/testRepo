
CREATE PROCEDURE dbo.spPO_GetProcessOrders
@PP_Id	 			int				= null
,@PathIds nvarchar(max)	= null -- comma separated pathIds to fetch the POs for
,@LineIds			nvarchar(max)	= null	-- Line to return PO details for
,@StatusSet			nvarchar(max)	= null	-- Set of status ID as a string
,@User_Id			int				= null
,@Start_Time datetime
,@End_Time datetime
,@Date_Filter_On nvarchar(max)	= null
,@Include_Unbounded_POs int = 0
,@Process_Order_Name nvarchar(max) = null
,@Path_Name nvarchar(max) = null
,@Prod_Code nvarchar(max) = null
,@pageSize int = 20
,@pageNum int = 0
,@TotalRowCount Int =0 OUTPUT




AS
    -- removing this check for now since we are not using userId
    /*
    IF NOT EXISTS(SELECT 1 FROM Users_Base WHERE User_id = @User_Id )
        BEGIN
            SELECT Error = 'ERROR: Valid User Required', Code = 'InsufficientPermission', ErrorType = 'ValidUserNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

     */


SELECT @PageNum = ISNULL(@PageNum,0),@Pagesize =ISNULL(@Pagesize,20)

    if(@PageNum < 0 OR @Pagesize < 1)
        BEGIN
            SELECT Error = 'ERROR: Invalid page parameters', Code = 'InvalidPage', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END


SELECT @Start_Time = dbo.fnServer_CmnConvertToDBTime(@Start_Time,'UTC')
SELECT @End_Time = dbo.fnServer_CmnConvertToDBTime(@End_Time,'UTC')
Declare @DatabaseTimeZone nvarchar(200)
select @DatabaseTimeZone = value from site_parameters where parm_id=192
    ----------------------------------------------------------------------------------------------------------------------------------
-- Parse the status set by into a temp table for later selection
----------------------------------------------------------------------------------------------------------------------------------

Select @LineIds = ltrim(rtrim(@LineIds))
SELECT @PathIds = ltrim(rtrim(@PathIds))
SELECT @StatusSet = ltrim(rtrim(@StatusSet))
SELECT @Process_Order_Name = ltrim(rtrim(@Process_Order_Name))
SELECT @Path_Name = ltrim(rtrim(@Path_Name))

    If(@LineIds = '') Select @LineIds = null
    If(@PathIds = '') Select @PathIds = null
    If(@StatusSet = '') Select @StatusSet = null
    If(@Process_Order_Name = '') select @Process_Order_Name = null
    If(@Path_Name = '') select @Path_Name = null
    If(@Prod_Code = '') select @Prod_Code = null

    Create Table #Paths (Id Int)
    INSERT INTO #Paths (Id)  --SELECT Id FROM dbo.fnCMN_IdListToTable('XYZ',@PathIds,',')
	SELECT col1 FROM dbo.fn_SplitString(@PathIds,',')

    -- Loading path related results in a table
    Create Table #PathSchedulePtUnit (RowID int IDENTITY,SchedulePointUnitId Int, SchedulePointUnitDesc nvarchar(4000) null, Path_Id Int, Path_Desc nvarchar(4000), LineId Int, LineDesc nvarchar(4000) Null, EngineeringUnit nvarchar(4000) Null,Production_Type int,Variable_Id int)


    IF @PathIds IS NULL
        Begin
            INSERT INTO #PathSchedulePtUnit(SchedulePointUnitId, SchedulePointUnitDesc, Path_Id, Path_Desc, LineId, LineDesc, EngineeringUnit) SELECT ppu.PU_Id, null, pth.Path_Id, pth.Path_Desc, pth.PL_Id, plb.PL_Desc, null
            from Prdexec_Paths pth 
                     JOIN PrdExec_Path_Units ppu   ON (ppu.Path_Id = pth.Path_Id AND ppu.Is_Schedule_Point = 1)
                     LEFT JOIN Prod_Lines_Base plb  ON pth.PL_Id = plb.PL_Id
        End
    Else
        Begin
            INSERT INTO #PathSchedulePtUnit(SchedulePointUnitId, SchedulePointUnitDesc, Path_Id, Path_Desc, LineId, LineDesc, EngineeringUnit) SELECT ppu.PU_Id, null, pth.Path_Id, pth.Path_Desc, pth.PL_Id, plb.PL_Desc, null
            from Prdexec_Paths pth 
                     JOIN PrdExec_Path_Units ppu   ON (ppu.Path_Id = pth.Path_Id AND ppu.Is_Schedule_Point = 1)
                     LEFT JOIN Prod_Lines_Base plb  ON pth.PL_Id = plb.PL_Id
            Where  pth.Path_Id in (Select Id from #Paths)
        End

    --  filtering for @Path_Name if it is passed
If(@Path_Name is not null)
    BEGIN
        Delete from #PathSchedulePtUnit where Path_Desc not like N'%' + @Path_Name + '%'
        SELECT  @Include_Unbounded_POs = 0 -- If path is provided then we won't be searching for unbounded POs
    end



--  filtering for @Prod_Code if it is passed
-- this is just first level filtering for product code, if a path has more than one prod, then that will be done at PO level
-- this will improve performance
If(@Prod_Code is not null)
    BEGIN
        Create Table #ProdFilteredPath(PathId INT)
        INSERT INTO #ProdFilteredPath Select pp.Path_Id from Prdexec_Paths pp JOIN PrdExec_Path_Products ppp ON ppp.Path_Id = pp.Path_Id JOIN Products_Base pb ON pb.Prod_Id = ppp.Prod_Id
        Where pb.Prod_Code like N'%' + @Prod_Code + '%'
        Delete from #PathSchedulePtUnit
        where Path_Id not in(Select Path_Id from #ProdFilteredPath)
    end



DECLARE @PathSchedulePtUnitRows INT, @PathSchedulePtUnitRow INT, @CurrentPUID INT, @ProductionType INT, @ProductionVarId INT, @CurrentPuDesc nvarchar(4000), @UOM nvarchar(4000);
SELECT @PathSchedulePtUnitRow = 0
SELECT @PathSchedulePtUnitRows  = Count(0) from #PathSchedulePtUnit

    --Check where is the production , from variable or events details
    --WHILE @PathSchedulePtUnitRow <  @PathSchedulePtUnitRows
    --    BEGIN
    --        SELECT @PathSchedulePtUnitRow = @PathSchedulePtUnitRow + 1
    --        SELECT @CurrentPUID = SchedulePointUnitId  FROM #PathSchedulePtUnit WHERE ROWID = @PathSchedulePtUnitRow

    --        SELECT    @ProductionType             = Production_Type,
    --                  @ProductionVarId            = Production_Variable,
    --            @CurrentPuDesc = PU_Desc
    --        FROM dbo.Prod_Units WITH (NOLOCK)
    --        WHERE PU_Id = @CurrentPUID
    --        IF @ProductionType = 1
    --            BEGIN
    --                SELECT    @UOM = Eng_Units
    --                FROM  dbo.Variables WITH (NOLOCK)
    --                WHERE Var_Id = @ProductionVarId
    --            END
    --        ELSE
    --            BEGIN
    --                SELECT @UOM =es.Dimension_X_Eng_Units FROM dbo.Event_Configuration ec WITH (NOLOCK)
    --                                                               JOIN prod_units pu WITH (NOLOCK)  ON ec.pu_id = pu.pu_id
    --                                                               JOIN Event_Subtypes es WITH (NOLOCK) ON ec.Event_Subtype_Id = es.Event_Subtype_Id
    --                WHERE pu.pu_id = @CurrentPUID and ec.ET_Id=1
    --            END
    --        UPDATE #PathSchedulePtUnit SET SchedulePointUnitDesc = @CurrentPuDesc, EngineeringUnit = @UOM where ROWID = @PathSchedulePtUnitRow
    --    END

Update pst set pst.SchedulePointUnitDesc = pu.PU_Desc,Pst.Production_Type = pu.Production_Type, pst.Variable_Id= pu.Production_Variable from #PathSchedulePtUnit Pst Join dbo.Prod_Units_base pu on pu.PU_Id =Pst.SchedulePointUnitId

update Pst set Pst.EngineeringUnit = vb.Eng_Units from #PathSchedulePtUnit Pst join Variables_base vb   on vb.Var_Id = Pst.Variable_Id where Pst.Production_Type = 1
Update Pst set Pst.EngineeringUnit = es.Dimension_X_Eng_Units from  #PathSchedulePtUnit Pst join Event_Configuration ec   on ec.PU_Id= Pst.SchedulePointUnitId join Event_Subtypes es  on ec.Event_Subtype_Id = es.Event_Subtype_Id where ec.ET_Id=1 and Pst.Production_Type <> 1








--DECLARE @POs TABLE
CREATE TABLE #POs
(
                      PP_Id  				int				Not Null
    ,Process_Order				nvarchar(4000)	Null
    ,Prod_Id			int				Not Null
    ,Prod_Desc		nvarchar(4000)	Null
    ,LineId             int Null
    ,LineDesc  nvarchar(4000)	Null
    ,SchedulePointUnitId int Null
    ,SchedulePointUnitDesc nvarchar(4000)	Null
    ,PP_Status			nvarchar(200)				Null
    ,PP_Status_Id			int				Null
    ,PP_Status_Order			int				Null
    ,PlannedStartTime	datetime		Null
    ,PlannedEndTime		datetime		Null
    ,PlannedQuantity float			Null
    ,Path_Id				int			 Null
    ,Path_Desc		nvarchar(4000)	Null
    ,BOM_Formulation_Id	bigint			Null
    ,BOM_Formulation_Desc      nvarchar(4000)	Null
    ,Control_Type		int				Null

    ,PP_Type_Id			int				Not Null

    ,Implied_Sequence	int				Null
    ,Implied_Sequence_Offset	int				Null
    ,Adjusted_Quantity	float			Null
    ,Actual_Bad_Quantity	float			Null
    ,Actual_Bad_Items int null
    ,Actual_Good_Quantity	float			Null
    ,Actual_Good_Items int null
    ,Actual_Start_Time  datetime		Null
    ,Actual_End_Time datetime Null
    ,Alarm_Count int null
    ,Actual_Down_Time float null
    ,Actual_Running_Time	float			Null
    ,Predicted_Remaining_Quantity	float			Null
    ,Predicted_Total_Duration     float Null
    ,Predicted_Remaining_Duration float Null
    ,Production_Rate		float			Null
    ,Comment_Id			int				Null
    ,User_Id				int				Not Null
    ,Block_Number nvarchar(4000)	Null
    ,User_General_1 nvarchar(4000) null
    ,User_General_2 nvarchar(4000) null
    ,User_General_3 nvarchar(4000) null
    ,Extended_Info nvarchar(4000) null
    ,Engineering_Unit nvarchar(4000) null
    ,Entry_On datetime		Null
    ,TotalPOCnt int)

Declare @PathSchedulePtUnit nvarchar(max)
IF EXISTS (SELECT 1 FROM  #PathSchedulePtUnit)
Begin
	SELECT @PathSchedulePtUnit = COALESCE(@PathSchedulePtUnit+',','')+ Cast(Path_Id as nvarchar) from #PathSchedulePtUnit
End

DECLARE @SQL nvarchar(max)
SELECT @SQL =''
SELECT @SQL='
;WITH TmpPOs (PP_Id, Process_Order, Prod_Id, Prod_Desc, LineId, LineDesc, SchedulePointUnitId, SchedulePointUnitDesc,  PP_Status, PP_Status_Id, PP_Status_Order, PlannedStartTime, PlannedEndTime, PlannedQuantity, Path_Id, Path_Desc,
 BOM_Formulation_Id, BOM_Formulation_Desc,  Control_Type, PP_Type_Id, Implied_Sequence, Implied_Sequence_Offset, Adjusted_Quantity, Actual_Bad_Quantity, Actual_Bad_Items,
                  Actual_Good_Quantity, Actual_Good_Items, Actual_Start_Time, Actual_End_Time, Alarm_Count, Actual_Down_Time, Actual_Running_Time, Predicted_Remaining_Quantity, Predicted_Total_Duration, Predicted_Remaining_Duration, Production_Rate,
                  Comment_Id, User_Id, Block_Number, User_General_1, User_General_2, User_General_3, Extended_Info, Engineering_Unit, Entry_On
    ) as (SELECT    po.PP_Id, po.Process_Order, po.Prod_Id, pb.Prod_Desc, pth.LineId, pth.LineDesc, pth.SchedulePointUnitId, pth.SchedulePointUnitDesc, ppst.PP_Status_Desc, po.PP_Status_Id, ppst.Status_Order, po.Forecast_Start_Date,
                    po.Forecast_End_Date, po.Forecast_Quantity, po.Path_Id, pth.Path_Desc, po.BOM_Formulation_Id,BOMF.BOM_Formulation_Desc, po.Control_Type, po.PP_Type_Id, po.Implied_Sequence, po.Implied_Sequence_Offset,
                    po.Adjusted_Quantity, po.Actual_Bad_Quantity, po.Actual_Bad_Items, po.Actual_Good_Quantity, po.Actual_Good_Items, po.Actual_Start_Time, po.Actual_End_Time, po.Alarm_Count, po.Actual_Down_Time, po.Actual_Running_Time, po.Predicted_Remaining_Quantity,
                    po.Predicted_Total_Duration, po.Predicted_Remaining_Duration, po.Production_Rate, po.Comment_Id, po.User_Id, po.Block_Number, po.User_General_1, po.User_General_2, po.User_General_3, po.Extended_Info, pth.EngineeringUnit, po.Entry_On
          FROM  Production_Plan po  
          LEFT JOIN production_plan_statuses ppst  ON po.PP_Status_Id = ppst.PP_Status_Id
          LEFT JOIN  #PathSchedulePtUnit pth  ON po.Path_Id = pth.Path_Id
          LEFT JOIN Products_Base pb  ON po.Prod_Id = pb.Prod_Id
          LEFT JOIN Bill_Of_Material_Formulation BOMF  ON  BOMF.BOM_Formulation_Id = po.BOM_Formulation_Id
WHERE 1=1
'
SELECT @SQL = @SQL+Case when @PP_Id is null then '' else ' AND '+cast(@PP_Id as nvarchar)+' = po.PP_Id ' end

IF(@Include_Unbounded_POs = 2) -- Normal use case scenario, where user just wants the unbounded POs
    BEGIN
        SELECT @SQL = @SQL + ' AND po.Path_Id is null'
    end
ELSE IF(@Include_Unbounded_POs = 1) -- Rare use case scenario, where user just wants unbounded and bounded POs, here just to make the APIs consistent. OR condition is justified here
    BEGIN
        SELECT @SQL = @SQL+Case when @PathIds is null then '' else ' AND (po.Path_Id in ('+@PathSchedulePtUnit+') OR po.Path_Id is null)'  end
        SELECT @SQL = @SQL+Case when @LineIds is null then '' else ' AND (pth.LineId in ('+@LineIds+') OR po.Path_Id is null)' end
    end
 ELSE IF(@Include_Unbounded_POs = 0) -- Normal use case scenario, where user just wants the bounded POs
        BEGIN
            SELECT @SQL = @SQL+Case when @PathIds is null then '' else ' AND po.Path_Id in ('+@PathSchedulePtUnit+')' end
            SELECT @SQL = @SQL+Case when @LineIds is null then '' else ' AND pth.LineId in ('+@LineIds+')' end
        end

    IF(@Process_Order_Name is not null)  -- searching for process order name. if executed, index of [path, Process order] will be used
        BEGIN
            select @SQL = @SQL + ' AND Process_Order like N''%' +  @Process_Order_Name+'%'''
        end
    IF(@Prod_Code is not null)
        BEGIN
            select @SQL = @SQL + ' AND pb.Prod_Code like N''%' +  @Prod_Code+'%'''
        end
SELECT @SQL = @SQL+Case when @StatusSet is null then '' else ' AND po.PP_Status_Id in ('+@StatusSet+')' end
IF @Date_Filter_On = 'ActualTime'
BEGIN
    SELECT @SQL = @SQL+Case when @Start_Time is null then '' else ' AND COALESCE(po.Actual_End_Time,po.Actual_Start_Time, po.Entry_On)  Between '''+convert(nvarchar,@Start_Time,9)+''' and '''+convert(nvarchar,@End_Time,9)+'''' end
END
ELSE
BEGIN
    SELECT @SQL = @SQL+Case when @Start_Time is null then '' else ' AND po.Forecast_Start_Date  Between '''+convert(nvarchar,@Start_Time,9)+''' and '''+convert(nvarchar,@End_Time,9)+'''' end
END

SELECT @SQL = @SQL+ ')'
SELECT @SQL = @SQL+' ,TotalCnt as (Select Count(0) TotalCnt from TmpPOs)'
SELECT @SQL = @SQL+
          'Select
                   * ,(Select TotalCnt from TotalCnt) from TmpPOs
               order by
                      COALESCE(PP_Status_Order,2147483647) ASC, Implied_Sequence ASC, ISNULL(Implied_Sequence_Offset,0) ASC
                   OFFSET '+cast((@PageSize*(@pageNum)) as nvarchar)+' ROWS
 FETCH NEXT  '+cast(@PageSize as nvarchar)+'   ROWS ONLY OPTION (RECOMPILE);'



INSERT INTO #POs(
PP_Id, Process_Order, Prod_Id, Prod_Desc, LineId, LineDesc, SchedulePointUnitId, SchedulePointUnitDesc, PP_Status, PP_Status_Id, PP_Status_Order, PlannedStartTime, PlannedEndTime, PlannedQuantity, Path_Id, Path_Desc,
BOM_Formulation_Id, BOM_Formulation_Desc,  Control_Type, PP_Type_Id, Implied_Sequence, Implied_Sequence_Offset, Adjusted_Quantity, Actual_Bad_Quantity, Actual_Bad_Items,
Actual_Good_Quantity, Actual_Good_Items, Actual_Start_Time, Actual_End_Time, Alarm_Count, Actual_Down_Time, Actual_Running_Time, Predicted_Remaining_Quantity, Predicted_Total_Duration, Predicted_Remaining_Duration, Production_Rate,
Comment_Id, User_Id, Block_Number,User_General_1 ,User_General_2 ,User_General_3, Extended_Info, Engineering_Unit, Entry_On, TotalPOCnt
)
EXEC(@SQL)







SET @TotalRowCount = (Select top 1 TotalPOCnt from #POs)

IF @TotalRowCount is NULL AND @pageNum > 0
    Begin
        SET @TotalRowCount = 0
        SELECT Error = 'ERROR: Page number out of range', Code = 'InvalidParameter', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
        RETURN
    End
IF @TotalRowCount is NULL
    Begin
        SET @TotalRowCount = 0
    End




IF (@PP_Id is not null) and (NOT EXISTS(SELECT 1 FROM #POs AS POS WHERE POS.PP_Id = @PP_Id))
    BEGIN
        SELECT Error = 'ERROR: Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
        RETURN
    END


SELECT
PP_Id
 ,Process_Order
 ,Prod_Id
 ,Prod_Desc
 ,LineId
 ,LineDesc
 ,SchedulePointUnitId
 ,SchedulePointUnitDesc
 ,PP_Status
 ,PlannedStartTime at time zone @DatabaseTimeZone at time zone 'UTC' as 'PlannedStartTime' -- = dbo.fnServer_CmnConvertFromDbTime(PlannedStartTime, 'UTC')
 ,PlannedEndTime at time zone @DatabaseTimeZone at time zone 'UTC' as 'PlannedEndTime'-- 		= dbo.fnServer_CmnConvertFromDbTime(PlannedEndTime, 'UTC')
 ,PlannedQuantity
 ,Path_Id
 ,Path_Desc
 ,BOM_Formulation_Id
 ,BOM_Formulation_Desc
 ,Control_Type
 ,PP_Type_Id
 ,Implied_Sequence
 ,Implied_Sequence_Offset
 ,Adjusted_Quantity
 ,Actual_Bad_Quantity
 ,Actual_Bad_Items
 ,Actual_Good_Quantity
 ,Actual_Good_Items
 ,Actual_Start_Time at time zone @DatabaseTimeZone at time zone 'UTC' as 'Actual_Start_Time'-- = dbo.fnServer_CmnConvertFromDbTime(Actual_Start_Time, 'UTC')
 ,Actual_End_Time at time zone @DatabaseTimeZone at time zone 'UTC' as 'Actual_End_Time' --  = dbo.fnServer_CmnConvertFromDbTime(Actual_End_Time, 'UTC')
 ,Alarm_Count
 ,Actual_Down_Time
 ,Actual_Running_Time
 ,Predicted_Remaining_Quantity
 ,Predicted_Total_Duration
 ,Predicted_Remaining_Duration
 ,Production_Rate
 ,Comment_Id
 ,User_Id
 ,Block_Number
 ,User_General_1
 ,User_General_2
 ,User_General_3
 ,Extended_Info
 ,Engineering_Unit
 ,Entry_On at time zone @DatabaseTimeZone at time zone 'UTC' as 'Entry_On'
FROM  #POs
order by
    COALESCE(PP_Status_Order,2147483647) ASC, Implied_Sequence ASC, ISNULL(Implied_Sequence_Offset,0) ASC



-- Order by PP Status Id is as per Product manager decision, Priority is in following order - Active, Next, Pending, Planning, Others

/*send the configured statuses, for running on unit error check on the update request */

--DECLARE @POStatusTransition TABLE
CREATE TABLE #POStatusTransition
(
    Path_Id				int			 Null
    ,From_PPStatus nvarchar(200)				Null
    ,To_PPStatus nvarchar(200)				Null
)

Insert into #POStatusTransition
SELECT
Path_Id, ppst_From.PP_Status_Desc as 'From_PPStatus', ppst_To.PP_Status_Desc as 'To_PPStatus'
from Production_Plan_Status pps
         JOIN production_plan_statuses ppst_From  ON pps.From_PPStatus_Id = ppst_From.PP_Status_Id
         JOIN production_plan_statuses ppst_To  ON pps.To_PPStatus_Id = ppst_To.PP_Status_Id
         where Path_Id in (Select Distinct Path_Id from #POs)


    -- For unbound: Following are the default transitions for unbounded
-- Pending to Next
-- Next to Pending and Active
-- Active to Pending and Complete
-- Complete to Active

-- Names needs to be loaded based on the Id because names might change
Declare @Pending_PPStatusUnb nvarchar(200), @Next_PPStatusUnb nvarchar(200), @Active_PPStatusUnb nvarchar(200), @Complete_PPStatusUnb nvarchar(200)
select @Pending_PPStatusUnb = PP_Status_Desc from production_plan_statuses where PP_Status_Id = 1
select @Next_PPStatusUnb = PP_Status_Desc from production_plan_statuses where PP_Status_Id = 2
select @Active_PPStatusUnb = PP_Status_Desc from production_plan_statuses where PP_Status_Id = 3
select @Complete_PPStatusUnb = PP_Status_Desc from production_plan_statuses where PP_Status_Id = 4


Insert into #POStatusTransition  values(-1, @Pending_PPStatusUnb, @Next_PPStatusUnb)

Insert into #POStatusTransition  values(-1, @Next_PPStatusUnb, @Pending_PPStatusUnb)
Insert into #POStatusTransition  values(-1, @Next_PPStatusUnb, @Active_PPStatusUnb)

Insert into #POStatusTransition  values(-1, @Active_PPStatusUnb, @Pending_PPStatusUnb)
Insert into #POStatusTransition  values(-1, @Active_PPStatusUnb, @Complete_PPStatusUnb)

Insert into #POStatusTransition  values(-1, @Complete_PPStatusUnb, @Active_PPStatusUnb)


Select * from #POStatusTransition


/*
TODO
This is an expensive operation. If it is not being used by anyone, we can remove this.
Plan is to display current running unit for the process orders on the grid
*/

/*
SELECT
PP_Start_Id, pps.PP_Id, Start_Time, End_Time, pub.PU_Id,pub.PU_Desc, Is_Production from Production_Plan_Starts as pps
                                                                                            LEFT JOIN Prod_Units_Base pub ON pps.PU_Id = pub.PU_Id
                                                                                            JOIN @POs POSAlias ON POSAlias.PP_Id = pps.PP_Id


*/


