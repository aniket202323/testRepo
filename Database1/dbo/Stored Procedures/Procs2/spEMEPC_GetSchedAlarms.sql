CREATE Procedure dbo.spEMEPC_GetSchedAlarms
@Path_Id int,
@User_Id int
AS
Declare @Eng_Units nvarchar(15),
@PU_Id int,
@Unit_Order int
While (0=0) 
  Begin
    select @Unit_Order = Min(Unit_Order) From PrdExec_Path_Units Where Path_Id = @Path_Id and Is_Production_Point = 1 and Unit_Order > Coalesce(@Unit_Order, 0)
    if @Unit_Order is NULL
      break
    Select @PU_Id = PU_Id From PrdExec_Path_Units Where Path_Id = @Path_id and Is_Production_Point = 1 and Unit_Order = @Unit_Order
    select @Eng_Units = es.dimension_x_eng_units
    from event_subtypes es
    join event_configuration ec on ec.Event_Subtype_Id = es.Event_Subtype_Id
    where pu_id = @PU_Id
    if @Eng_Units is NOT NULL
      break
   End
Select pepat.PEPAT_Desc as 'Description', 
  Case When pepat.Threshold_Type = 0 Then 'No Threshold'
       When pepat.Threshold_Type = 1 Then '%Only'
       When pepat.Threshold_Type = 2 Then 'Quantity Only'
       When pepat.Threshold_Type = 3 Then 'Time Only'
       When pepat.Threshold_Type = 4 Then 'Quantity + %'
       When pepat.Threshold_Type = 5 Then 'Time + %'
       When pepat.Threshold_Type = 6 Then 'Status' End as 'Threshold Type', 
  Case When pepat.Threshold_Type = 6 Then (Select PP_Status_Desc From Production_Plan_Statuses Where PP_Status_Id = pepa.Threshold_Value)
  Else Convert(nvarchar(50), pepa.Threshold_Value) End as 'Threshold Value',
  Case When pepat.Threshold_Type = 0 Then NULL
       When pepat.Threshold_Type = 1 Then '%'
       When pepat.Threshold_Type = 2 Then Coalesce(@Eng_Units, pepat.Threshold_Eng_Units)
       When pepat.Threshold_Type = 3 Then pepat.Threshold_Eng_Units
       When pepat.Threshold_Type = 4 Then Case When pepa.Threshold_Type_Selection = 2 Then Coalesce(@Eng_Units, pepat.Threshold_Eng_Units) Else '%' End
       When pepat.Threshold_Type = 5 Then Case When pepa.Threshold_Type_Selection = 2 Then pepat.Threshold_Eng_Units Else '%' End
       When pepat.Threshold_Type = 6 Then NULL End as 'Units',
  ap.AP_Desc as 'Priority',
  pepat.Threshold_Type as 'Threshold_Type', 
  Case When pepat.Threshold_Type = 6 Then pepa.Threshold_Value
  Else NULL End as 'Threshold_Value_Id',
  pepat.PEPAT_Id, pepa.PEPA_Id
From PrdExec_Path_Alarm_Types pepat
Left Outer Join PrdExec_Path_Alarms pepa on pepa.PEPAT_Id = pepat.PEPAT_Id and pepa.Path_Id = @Path_Id
Left Outer Join Alarm_Priorities ap on ap.AP_Id = pepa.AP_Id
Order By pepat.PEPAT_Desc
