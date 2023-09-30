CREATE Procedure dbo.spEMEPC_GetAvailAlarms
@Path_Id int,
@PEPAT_Id int,
@User_Id int,
@Threshold_Type_Selection tinyint = NULL,
@Threshold_Value nvarchar(50) = NULL,
@AP_Id int = NULL,
@PEPA_Id int = NULL
AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_GetAvailAlarms',
             Convert(nVarChar(10),@Path_Id) + ','  + 
             Convert(nVarChar(10),@PEPAT_Id) + ','  + 
             Convert(nVarChar(10),@User_Id) + ','  + 
             @Threshold_Value + ','  + 
             Convert(nVarChar(10),@AP_Id) + ','  + 
             Convert(nVarChar(10),@PEPA_Id) + ','  + 
             Convert(nVarChar(10),@Threshold_Type_Selection), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @PEPA_Id is NULL
  Begin
    If @Threshold_Value is NULL and @Threshold_Type_Selection is NULL and @AP_Id is NULL
      Begin
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
        Select PP_Status_Id, PP_Status_Desc From Production_Plan_Statuses Order By PP_Status_Desc ASC
        Select PPA.Threshold_Type_Selection, PPA.Threshold_Value, PPAT.Threshold_Type,
          Case When PPAT.Threshold_Type = 0 Then NULL
               When PPAT.Threshold_Type = 1 Then '%'
               When PPAT.Threshold_Type = 2 Then Coalesce(@Eng_Units, PPAT.Threshold_Eng_Units)
               When PPAT.Threshold_Type = 3 Then PPAT.Threshold_Eng_Units
               When PPAT.Threshold_Type = 4 Then '%'
               When PPAT.Threshold_Type = 5 Then '%'
               When PPAT.Threshold_Type = 6 Then NULL End as 'Option1',
          Case When PPAT.Threshold_Type = 0 Then NULL
               When PPAT.Threshold_Type = 1 Then NULL
               When PPAT.Threshold_Type = 2 Then NULL
               When PPAT.Threshold_Type = 3 Then NULL
               When PPAT.Threshold_Type = 4 Then Coalesce(@Eng_Units, PPAT.Threshold_Eng_Units)
               When PPAT.Threshold_Type = 5 Then PPAT.Threshold_Eng_Units
               When PPAT.Threshold_Type = 6 Then NULL End as 'Option2',
          PPA.AP_Id
          From PrdExec_Path_Alarm_Types PPAT
          Left Outer Join PrdExec_Path_Alarms PPA on PPA.PEPAT_Id = PPAT.PEPAT_Id and PPA.Path_Id = @Path_Id
          Where PPAT.PEPAT_Id = @PEPAT_Id
      End
    Else
      Begin
        Select @PEPA_Id = PEPA_Id From PrdExec_Path_Alarms Where Path_Id = @Path_Id And PEPAT_Id = @PEPAT_Id
        If @PEPA_Id is NULL
          Begin
            Insert Into PrdExec_Path_Alarms (Path_Id, PEPAT_Id, Threshold_Type_Selection, Threshold_Value, AP_Id) Values (@Path_Id, @PEPAT_Id, @Threshold_Type_Selection, @Threshold_Value, @AP_Id)
            Select @PEPA_Id = Scope_Identity()
          End
      End
  End
Else If @PEPA_Id is NOT NULL
  Begin
    If @Threshold_Value is NOT NULL
      Begin
        Update PrdExec_Path_Alarms Set Threshold_Value = @Threshold_Value, Threshold_Type_Selection = @Threshold_Type_Selection, AP_Id = @AP_Id
          Where PEPA_Id = @PEPA_Id
      End
    Else
      Begin
        Delete From PrdExec_Path_Alarms
          Where PEPA_Id = @PEPA_Id 
      End
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
