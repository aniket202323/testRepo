
CREATE PROCEDURE dbo.spPO_GetHistoryV1
@PP_Id	 			int				= null




AS
    IF (NOT EXISTS(SELECT 1 FROM Production_Plan WHERE PP_Id = @PP_Id))
        BEGIN
            SELECT Error = 'ERROR: Process Order not found', Code = 'ResourceNotFound', ErrorType = 'ProcessOrderNotFound', PropertyName1 = '', PropertyName2 = '', PropertyName3 = '', PropertyName4 = '', PropertyValue1 = '', PropertyValue2 = '', PropertyValue3 = '', PropertyValue4 = ''
            RETURN
        END

Declare @DatabaseTimeZone nvarchar(200)
select @DatabaseTimeZone = value from site_parameters where parm_id=192

    select pph.Entry_On at time zone @DatabaseTimeZone at time zone 'UTC' as 'Entry_On', pph.Prod_Id, pb.Prod_Desc,
           pph.User_Id, UB.Username, pph.PP_Type_Id, pph.Actual_Bad_Items, pph.Actual_Bad_Quantity,
           pph.Actual_Down_Time, pph.Actual_End_Time at time zone @DatabaseTimeZone at time zone 'UTC' as 'Actual_End_Time',
           pph.Actual_Good_Items, pph.Actual_Good_Quantity, pph.Actual_Repetitions, pph.Actual_Running_Time,
           pph.Actual_Start_Time at time zone @DatabaseTimeZone at time zone 'UTC' as 'Actual_Start_Time', pph.Adjusted_Quantity, pph.Alarm_Count, pph.Block_Number, pph.BOM_Formulation_Id, BOMF.BOM_Formulation_Desc ,pph.Comment_Id, pph.Extended_Info,
           pph.Forecast_End_Date at time zone @DatabaseTimeZone at time zone 'UTC' as 'Forecast_End_Date', pph.Forecast_Start_Date at time zone @DatabaseTimeZone at time zone 'UTC' as 'Forecast_Start_Date',   pph.Forecast_Quantity,  pph.Implied_Sequence, pph.Late_Items,
           pph.Parent_PP_Id, pph.Source_PP_Id,
           pph.Path_Id, PP.Path_Desc,
           pph.Predicted_Remaining_Duration, pph.Predicted_Remaining_Quantity, pph.Predicted_Total_Duration, pph.PP_Id, pph.Process_Order, pph.Production_Rate,
           pph.User_General_1, pph.User_General_2, pph.User_General_3, pph.Control_Type, ppst.PP_Status_Desc, pph.Modified_On at time zone @DatabaseTimeZone at time zone 'UTC' as 'Modified_On', pph.DBTT_Id as 'TransactionType'



    from Production_Plan_History pph
        LEFT JOIN Products_Base pb WITH (nolock) ON pph.Prod_Id = pb.Prod_Id
        LEFT JOIN Production_Plan_Statuses ppst ON pph.PP_Status_Id = ppst.PP_Status_Id
        LEFT JOIN Users_Base UB WITH (nolock) on pph.User_Id = UB.User_Id
        LEFT JOIN Prdexec_Paths PP WITH (nolock) on pph.Path_Id = PP.Path_Id
        LEFT JOIN Bill_Of_Material_Formulation BOMF WITH (nolock) on BOMF.BOM_Formulation_Id = pph.BOM_Formulation_Id
    where PP_Id = @PP_Id
