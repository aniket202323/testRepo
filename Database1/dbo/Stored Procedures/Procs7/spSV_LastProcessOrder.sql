Create Procedure dbo.spSV_LastProcessOrder
@Sheet_Id int,
@Path_Id int,
@Start_Time datetime,
@DisplayUnboundOrders bit,
@LastTime datetime OUTPUT
AS
Declare @Max_Implied_Sequence int
Select @Max_Implied_Sequence = NULL
If @Path_Id > 0
  Select @DisplayUnboundOrders = 0
Else
  Select @Path_Id = NULL
If @DisplayUnboundOrders = 1
  Begin
    Select @Max_Implied_Sequence = Max(Implied_Sequence)
    From Production_Plan
    Where (Path_Id in (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id) or Path_Id is NULL)
    And Prod_Id in (Select Prod_Id From PrdExec_Path_Products Where Path_Id In (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id))
    And PP_Status_Id = 3
    And Forecast_Start_Date <= @Start_Time
    If @Max_Implied_Sequence is NULL
      Select @Max_Implied_Sequence = Max(Implied_Sequence)
      From Production_Plan
      Where (Path_Id in (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id) or Path_Id is NULL)
      And Prod_Id in (Select Prod_Id From PrdExec_Path_Products Where Path_Id In (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id))
      And Forecast_Start_Date <= @Start_Time
    Select @LastTime = Max(Forecast_Start_Date)
    From Production_Plan
    Where (Path_Id in (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id) or Path_Id is NULL)
    And Prod_Id in (Select Prod_Id From PrdExec_Path_Products Where Path_Id In (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id))
    And Implied_Sequence = @Max_Implied_Sequence
  End
Else
  Begin
    If @Path_Id is NULL
      Begin
        Select @Max_Implied_Sequence = Max(Implied_Sequence)
        From Production_Plan
        Where Path_Id in (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id)
        And PP_Status_Id = 3
        And Forecast_Start_Date <= @Start_Time
        If @Max_Implied_Sequence is NULL
          Select @Max_Implied_Sequence = Max(Implied_Sequence)
          From Production_Plan
          Where Path_Id in (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id)
          And Forecast_Start_Date <= @Start_Time
        Select @LastTime = Max(Forecast_Start_Date)
        From Production_Plan
        Where Path_Id in (Select Path_Id From Sheet_Paths Where Sheet_Id = @Sheet_Id)
        And Implied_Sequence = @Max_Implied_Sequence
      End
    Else
      Begin
        Select @Max_Implied_Sequence = Max(Implied_Sequence)
        From Production_Plan
        Where Path_Id = @Path_Id
        And PP_Status_Id = 3
        And Forecast_Start_Date <= @Start_Time
        If @Max_Implied_Sequence is NULL
          Select @Max_Implied_Sequence = Max(Implied_Sequence)
          From Production_Plan
          Where Path_Id  = @Path_Id
          And Forecast_Start_Date <= @Start_Time
        Select @LastTime = Max(Forecast_Start_Date)
        From Production_Plan
        Where Path_Id  = @Path_Id
        And Implied_Sequence = @Max_Implied_Sequence
      End
  End
If @LastTime Is Null Select @LastTime = dbo.fnServer_CmnGetDate(getUTCdate())
return(100)
