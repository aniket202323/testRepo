Create Procedure dbo.spAL_ScrollSheet
  @Sheet_Desc nVarchar(50),
  @Start_Time datetime,
  @End_Time datetime,
  @DecimalSep char(1) = '.'
 AS
--JG Added this for regional settings:
--  Must replace the period in the result value with a comma if the 
--  passed decimal separator is not a period.
Select @DecimalSep = COALESCE(@DecimalSep,'.')
--JG END
  -- Declare local variables.
  DECLARE @Sheet_id int,
          @Event_Type tinyint,
          @Interval smallint,
          @Offset smallint,
          @RowsFound int,
          @MasterUnit int,
          @GetAlarms int,
          @TooManyAlarms tinyint,
          @Sheet_Type int
  -- Get general sheet information.
  SELECT @Sheet_Id = Sheet_Id,
         @Event_Type = Event_Type,
         @Interval = Interval,
         @Offset = Offset,
         @MasterUnit = Master_Unit,
         @Sheet_Type = Sheet_Type
    FROM Sheets
    WHERE (Sheet_Desc = @Sheet_Desc)
  -- Determine whether or not to retrieve alarm infomation
  SELECT @GetAlarms = Coalesce(Value, 0) From Sheet_Display_Options Where Display_option_id = 164 and Sheet_Id = @Sheet_id
  -- Create temporary table containing all the variables on named sheet.
  Create Table #Var (
         Var_Id int,
         Var_Order int,
         PU_Id int
 	  	  	  	  )
  Insert into #Var (Var_Id, Var_Order,PU_Id)
  SELECT sv.Var_Id,
         sv.Var_Order,
         v.PU_Id
    FROM Sheet_Variables sv
    JOIN Variables v on v.Var_id = sv.Var_Id
    WHERE (sv.Sheet_Id = @Sheet_Id)
    ORDER BY sv.Var_Order
  -- Create a temporary table containing the specific times (columns) on the sheet. The method used
  -- to construnct this temporary table will vary according to sheet type (e.g. event-, time-, or
  -- interval-based sheets).
  Create Table #Col (
         Result_On datetime,
         Event_Id int,
         Event_Num nvarchar(25),
         Event_Status int,
         Comment_Id int,
         Applied_Product int,
         Conformance tinyint,
         Testing_Prct_Complete tinyint
         )
  If @Sheet_Type = 2
    Begin
 	  	   Insert into #Col (Result_On,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,Conformance,Testing_Prct_Complete)
 	  	   SELECT TimeStamp,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,Conformance,Testing_Prct_Complete
 	  	     FROM Events
 	  	     WHERE (@Event_Type = 1) AND
 	  	           (Pu_Id = @MasterUnit) AND
 	  	           (TimeStamp >= @Start_Time) AND
 	  	           (TimeStamp <=  @End_Time)
        ORDER BY TimeStamp DESC
    End
  Else
    Begin
 	  	   Insert into #Col (Result_On,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,Conformance,Testing_Prct_Complete)
   	  	 SELECT Result_On,0,NULL,NULL,Comment_Id,Null,NULL,NULL
 	  	     FROM Sheet_Columns
 	  	     WHERE (@Event_Type = 0) AND
 	  	           (Sheet_Id = @Sheet_Id) AND
 	  	           (Result_On >= @Start_Time) AND
 	  	           (Result_On <= @End_Time)
 	  	     ORDER BY Result_On DESC
    End
  -- Remember the number of rows obtained.
  SELECT @RowsFound = @@ROWCOUNT
  Create Table #Alarms (
    Alarm_Id int,
    Start_Time datetime,
    End_Time datetime,
    Alarm_Desc nvarchar(1000),
    Key_Id int
    )
  -- Create temporary table containing all the tests on the named sheet at given times.
  Create Table #Tst (
         Test_Id BigInt,
         Canceled bit,
         Result_On datetime,
         Entry_On datetime,
         Entry_By int,
         Comment_Id int,
         Array_Id int,
         Event_Id int,
         Var_Id int,
         Locked tinyint,
         Result nvarchar(25),
         Second_User_Id int,
         PU_Id int,
         Alarm_Id int,
         Alarm_Start_Time datetime,
         Alarm_End_Time datetime,
         Alarm_Desc nvarchar(1000),
         Has_History int
         )
  Insert into #Tst (Test_Id,Canceled,Result_On,Entry_On,Entry_By,Comment_Id,Array_Id,Event_Id,
                    Var_Id,Locked,Result,Second_User_Id,PU_Id,Alarm_Id,Alarm_Start_Time,Alarm_End_Time,Alarm_Desc,Has_History)
  SELECT t.Test_Id,t.Canceled,t.Result_On,t.Entry_On,t.Entry_By,t.Comment_Id,t.Array_Id,t.Event_Id,
         t.Var_Id,t.Locked,t.Result,t.Second_User_Id, v.PU_Id, Coalesce(a.Alarm_Id,0), a.Start_Time, 
         a.End_Time, a.Alarm_Desc, Case When Count(th.Test_Id) > 1 then 1 else 0 end
    FROM Tests t 
    join #Var v on v.var_id = t.var_id
    join #Col c on c.result_on = t.result_on
    left Outer Join #Alarms a on a.Key_Id = t.Var_Id and
                                t.Result_On >= a.Start_Time and
                               (t.Result_On < a.End_time or a.End_Time is Null)                          
    left Outer Join Test_History th on th.Test_Id = t.Test_Id and th.Entry_By <> 5
    Where t.result_on >= @Start_Time and t.result_on <= @End_Time
      Group By t.Test_Id,t.Canceled,t.Result_On,t.Entry_On,t.Entry_By,t.Comment_Id,t.Array_Id,t.Event_Id,
         t.Var_Id,t.Locked,t.Result,t.Second_User_Id, v.PU_Id, Coalesce(a.Alarm_Id,0), a.Start_Time, 
         a.End_Time, a.Alarm_Desc
  -- Return resultset [#1/4] indicating sheet information.
  SELECT Sheet_Id = @Sheet_Id, 	  	  	  	 -- sheet identifier
         Time_Count = (SELECT COUNT(*) FROM #Col) 	 -- number of distinct times
  -- Return resultset [#2/4] containing distinct times.
  SELECT Result_On,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,Conformance,Testing_Prct_Complete
    FROM #Col
    ORDER BY Result_On
  -- Drop the temporary times table.
  DROP TABLE #Col
  -- Drop the temporaty variables table.
  DROP TABLE #Var
  -- Return resultset [#3/4] containing the test information.
  SELECT 
   T.Test_Id,
   T.Canceled,
   T.Result_On,
   T.Entry_On,
   T.Entry_By,
   T.Comment_Id,
   T.Array_Id,
   T.Event_Id,
   T.Var_Id,
   T.Locked,
   T.Alarm_Id,
   T.Alarm_Start_Time,
   T.Alarm_End_Time,
   T.Alarm_Desc,
   Result = CASE 
              WHEN @DecimalSep <> '.' and V.Data_Type_Id = 2 THEN REPLACE(T.Result, '.', @DecimalSep)
              ELSE T.Result
              END
    FROM #Tst T
    JOIN Variables v on t.Var_Id = v.Var_Id
-- Return resultset [#4/4] - 0 if OK to process alarms, 1 if too many
--  Select @TooManyAlarms as TooManyAlarms
  -- Drop the remaining temporary tables.
  DROP TABLE #Tst
  DROP TABLE #Alarms
