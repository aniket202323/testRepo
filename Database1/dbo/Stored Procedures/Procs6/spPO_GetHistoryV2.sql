
CREATE PROCEDURE dbo.spPO_GetHistoryV2
@PP_Id	 			int				= null
,@pageSize int = 20
,@pageNum int = 0
,@TotalRowCount Int = 0 OUTPUT




AS
    IF (NOT EXISTS(SELECT 1 FROM Production_Plan WHERE PP_Id = @PP_Id))
        BEGIN
            SELECT Error = 'ERROR: Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

SELECT @PageNum = ISNULL(@PageNum,0),@Pagesize =ISNULL(@Pagesize,20)

    if(@PageNum < 0 OR @Pagesize < 1)
        BEGIN
            SELECT Error = 'ERROR: Invalid page parameters', Code = 'InvalidPage', ErrorType = '', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

Declare @DatabaseTimeZone nvarchar(200)
select @DatabaseTimeZone = value from site_parameters where parm_id=192





DECLARE @POHistory TABLE(
     Entry_On  	datetime		Null
    ,Prod_Id			int				Not Null
    ,Prod_Desc		nvarchar(4000)	Null
    ,User_Id				int				Not Null
    ,Username nvarchar(4000)	Null
    ,PP_Type_Id			int				Not Null
    ,Actual_Bad_Items int null
    ,Actual_Bad_Quantity	float			Null
    ,Actual_Down_Time float null
    ,Actual_End_Time datetime Null
    ,Actual_Good_Items int null
    ,Actual_Good_Quantity	float			Null
    ,Actual_Repetitions int null
    ,Actual_Running_Time	float			Null
    ,Actual_Start_Time  datetime		Null
    ,Adjusted_Quantity	float			Null
    ,Alarm_Count int null
    ,Block_Number nvarchar(4000)	Null
    ,BOM_Formulation_Id	bigint			Null
    ,BOM_Formulation_Desc      nvarchar(4000)	Null
    ,Comment_Id			int				Null
    ,Extended_Info nvarchar(4000) null
    ,Forecast_End_Date datetime Null
    ,Forecast_Start_Date datetime Null
    ,Forecast_Quantity float			Null
    ,Implied_Sequence	int				Null
    ,Late_Items int				Null
    ,Parent_PP_Id int				Null
    ,Source_PP_Id int null
    ,Path_Id				int			 Null
    ,Path_Desc		nvarchar(4000)	Null
    ,Predicted_Remaining_Duration float Null
    ,Predicted_Remaining_Quantity	float			Null
    ,Predicted_Total_Duration     float Null
    ,PP_Id int NULL
    ,Process_Order				nvarchar(4000)	Null
    ,Production_Rate		float			Null
    ,User_General_1 nvarchar(4000) null
    ,User_General_2 nvarchar(4000) null
    ,User_General_3 nvarchar(4000) null
    ,Control_Type		int				Null
    ,PP_Status_Id			int				Null
    ,PP_Status		nvarchar(200) null -- Only 50 characters are supported from PA admin
    ,Modified_On datetime Null
    ,TransactionType int null
    ,TotalPOHistoryCnt int)




DECLARE @SQL nvarchar(max)
SELECT @SQL =''
SELECT @SQL='
;WITH TmpPOHistory (Entry_On
    ,Prod_Id
    ,Prod_Desc
    ,User_Id
    ,Username
    ,PP_Type_Id
    ,Actual_Bad_Items
    ,Actual_Bad_Quantity
    ,Actual_Down_Time
    ,Actual_End_Time
    ,Actual_Good_Items
    ,Actual_Good_Quantity
    ,Actual_Repetitions
    ,Actual_Running_Time
    ,Actual_Start_Time
    ,Adjusted_Quantity
    ,Alarm_Count
    ,Block_Number
    ,BOM_Formulation_Id
    ,BOM_Formulation_Desc
    ,Comment_Id
    ,Extended_Info
    ,Forecast_End_Date
    ,Forecast_Start_Date
    ,Forecast_Quantity
    ,Implied_Sequence
    ,Late_Items
    ,Parent_PP_Id
    ,Source_PP_Id
    ,Path_Id
    ,Path_Desc
    ,Predicted_Remaining_Duration
    ,Predicted_Remaining_Quantity
    ,Predicted_Total_Duration
    ,PP_Id
    ,Process_Order
    ,Production_Rate
    ,User_General_1
    ,User_General_2
    ,User_General_3
    ,Control_Type
    ,PP_Status_Id
    ,PP_Status
    ,Modified_On
    ,TransactionType
    ) as (select pph.Entry_On, pph.Prod_Id, pb.Prod_Desc,
       pph.User_Id, UB.Username, pph.PP_Type_Id, pph.Actual_Bad_Items, pph.Actual_Bad_Quantity,
       pph.Actual_Down_Time, pph.Actual_End_Time,
       pph.Actual_Good_Items, pph.Actual_Good_Quantity, pph.Actual_Repetitions, pph.Actual_Running_Time,
       pph.Actual_Start_Time, pph.Adjusted_Quantity, pph.Alarm_Count, pph.Block_Number, pph.BOM_Formulation_Id, BOMF.BOM_Formulation_Desc ,pph.Comment_Id, pph.Extended_Info,
       pph.Forecast_End_Date, pph.Forecast_Start_Date,   pph.Forecast_Quantity,  pph.Implied_Sequence, pph.Late_Items,
       pph.Parent_PP_Id, pph.Source_PP_Id,
       pph.Path_Id, PP.Path_Desc,
       pph.Predicted_Remaining_Duration, pph.Predicted_Remaining_Quantity, pph.Predicted_Total_Duration, pph.PP_Id, pph.Process_Order, pph.Production_Rate,
       pph.User_General_1, pph.User_General_2, pph.User_General_3, pph.Control_Type, pph.PP_Status_Id, ppst.PP_Status_Desc, pph.Modified_On, pph.DBTT_Id

from Production_Plan_History pph
         LEFT JOIN Production_Plan_Statuses ppst ON pph.PP_Status_Id = ppst.PP_Status_Id
         LEFT JOIN Products_Base pb WITH (nolock) ON pph.Prod_Id = pb.Prod_Id
         LEFT JOIN Users_Base UB WITH (nolock) on pph.User_Id = UB.User_Id
         LEFT JOIN Prdexec_Paths PP WITH (nolock) on pph.Path_Id = PP.Path_Id
         LEFT JOIN Bill_Of_Material_Formulation BOMF WITH (nolock) on BOMF.BOM_Formulation_Id = pph.BOM_Formulation_Id
where PP_Id = '
SELECT @SQL = @SQL + cast(@PP_Id as nvarchar)
SELECT @SQL = @SQL+ ')'
SELECT @SQL = @SQL+' ,TotalCnt as (Select Count(0) TotalCnt from TmpPOHistory)'
SELECT @SQL = @SQL+
              'Select
                       * ,(Select TotalCnt from TotalCnt) from TmpPOHistory
                   order by
                          Entry_On DESC
                       OFFSET '+cast((@PageSize*(@pageNum)) as nvarchar)+' ROWS
 FETCH NEXT  '+cast(@PageSize as nvarchar)+'   ROWS ONLY OPTION (RECOMPILE);'



INSERT INTO @POHistory(Entry_On
                      ,Prod_Id
                      ,Prod_Desc
                      ,User_Id
                      ,Username
                      ,PP_Type_Id
                      ,Actual_Bad_Items
                      ,Actual_Bad_Quantity
                      ,Actual_Down_Time
                      ,Actual_End_Time
                      ,Actual_Good_Items
                      ,Actual_Good_Quantity
                      ,Actual_Repetitions
                      ,Actual_Running_Time
                      ,Actual_Start_Time
                      ,Adjusted_Quantity
                      ,Alarm_Count
                      ,Block_Number
                      ,BOM_Formulation_Id
                      ,BOM_Formulation_Desc
                      ,Comment_Id
                      ,Extended_Info
                      ,Forecast_End_Date
                      ,Forecast_Start_Date
                      ,Forecast_Quantity
                      ,Implied_Sequence
                      ,Late_Items
                      ,Parent_PP_Id
                      ,Source_PP_Id
                      ,Path_Id
                      ,Path_Desc
                      ,Predicted_Remaining_Duration
                      ,Predicted_Remaining_Quantity
                      ,Predicted_Total_Duration
                      ,PP_Id
                      ,Process_Order
                      ,Production_Rate
                      ,User_General_1
                      ,User_General_2
                      ,User_General_3
                      ,Control_Type
                      ,PP_Status_Id
                      ,PP_Status
                      ,Modified_On
                      ,TransactionType, TotalPOHistoryCnt)
    EXEC(@SQL)






    SET @TotalRowCount = (Select top 1 TotalPOHistoryCnt from @POHistory)

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



Select Entry_On  at time zone @DatabaseTimeZone at time zone 'UTC' as 'Entry_On'
     ,Prod_Id
     ,Prod_Desc
     ,User_Id
     ,Username
     ,PP_Type_Id
     ,Actual_Bad_Items
     ,Actual_Bad_Quantity
     ,Actual_Down_Time
     ,Actual_End_Time  at time zone @DatabaseTimeZone at time zone 'UTC' as 'Actual_End_Time'
     ,Actual_Good_Items
     ,Actual_Good_Quantity
     ,Actual_Repetitions
     ,Actual_Running_Time
     ,Actual_Start_Time  at time zone @DatabaseTimeZone at time zone 'UTC' as 'Actual_Start_Time'
     ,Adjusted_Quantity
     ,Alarm_Count
     ,Block_Number
     ,BOM_Formulation_Id
     ,BOM_Formulation_Desc
     ,Comment_Id
     ,Extended_Info
     ,Forecast_End_Date  at time zone @DatabaseTimeZone at time zone 'UTC' as 'Forecast_End_Date'
     ,Forecast_Start_Date  at time zone @DatabaseTimeZone at time zone 'UTC' as 'Forecast_Start_Date'
     ,Forecast_Quantity
     ,Implied_Sequence
     ,Late_Items
     ,Parent_PP_Id
     ,Source_PP_Id
     ,Path_Id
     ,Path_Desc
     ,Predicted_Remaining_Duration
     ,Predicted_Remaining_Quantity
     ,Predicted_Total_Duration
     ,PP_Id
     ,Process_Order
     ,Production_Rate
     ,User_General_1
     ,User_General_2
     ,User_General_3
     ,Control_Type
     ,PP_Status
     ,Modified_On  at time zone @DatabaseTimeZone at time zone 'UTC' as 'Modified_On'
     ,TransactionType
From @POHistory order by Entry_On DESC






