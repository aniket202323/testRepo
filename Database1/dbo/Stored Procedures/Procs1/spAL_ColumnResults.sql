Create Procedure dbo.spAL_ColumnResults
  @Sheet_Desc Nvarchar(50),
  @Result_On datetime, 
  @DecimalSep char(1) = '.'
 AS
  Declare @Sheet_Id int
  Declare @GetAlarms int
  Declare @ShowTestHistory int
  Declare @TooManyAlarms tinyint
  Select @Sheet_Id = Sheet_Id From Sheets Where Sheet_Desc = @Sheet_Desc
  Select @GetAlarms = ISNULL(Value,0) From Sheet_Display_Options Where Sheet_Id = @Sheet_Id and Display_Option_Id = 164
  Select @ShowTestHistory = ISNULL(Value,0) From Sheet_Display_Options Where Sheet_Id = @Sheet_Id and Display_Option_Id = 378
  Declare @Vars Table( 	 Var_Id int,
 	  	  	  	  	  	 Var_Order int, 	  	  	  	  	 -- MKW 2006/11/02
 	  	  	  	  	  	 Data_Type_Id int,
 	  	  	  	  	  	 PRIMARY KEY(Var_Id, Var_Order)) 	 -- MKW 2006/11/02
  -- Select The Variables We Care About
  Insert Into @Vars(Var_id,
 	  	  	  	  	 Var_Order, 	  	 -- MKW 2006/11/02
 	  	  	  	  	 Data_Type_Id)
  SELECT 	 v.Var_Id,
 	  	  	 s.Var_Order,  	  	  	 -- MKW 2006/11/02
 	  	  	 v.Data_Type_Id
    FROM Sheet_Variables s
    Join Variables v on v.var_id = s.var_id
    Where s.Sheet_Id = @Sheet_Id
  -- Create temporary table containing all the alarms for variables on this sheet
  Declare @Alarms Table (
    Alarm_Id int,
    Start_Time datetime,
    End_Time datetime,
    Alarm_Desc nvarchar(1000),
    Key_Id int,
 	 PRIMARY KEY (Key_Id, Start_Time, Alarm_Id) 	 -- MKW 2006/11/02
    )
  If @GetAlarms <> 0
    BEGIN
      -- Populate temporary table containing all the alarms for variables on this sheet (If sheet displays Alarms)
      Insert Into @Alarms (Alarm_Id, Start_Time ,End_Time , Alarm_Desc, Key_Id )
        SELECT top 1001 a.Alarm_Id, a.Start_Time, a.End_Time, a.Alarm_Desc, a.Key_Id
        FROM Alarms a
        join @Vars v on v.var_id = a.key_Id
        Where a.End_Time >= @Result_On or a.End_Time is Null and a.Alarm_Type_Id in (1,2,4)
      If @@Rowcount = 1001
        BEGIN
          Select @TooManyAlarms = 1
          Delete From @Alarms
        END
      else
        BEGIN
          Select @TooManyAlarms = 0
        END
    END
  ELSE 
    BEGIN
      Select @TooManyAlarms = 0
    END
  IF @ShowTestHistory = 1 	 -- MKW 2006/11/02
 	 BEGIN
 	   -- Select Result Information.
 	   SELECT v.Var_Id
 	          ,t.Test_Id
 	          ,t.Var_Id
 	          ,t.Result_On
 	          ,t.Canceled
 	          ,Result = CASE 
 	                         WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(T.Result, '.', @DecimalSep)
 	                         ELSE T.Result
 	                       END
 	          ,t.Entry_On
 	          ,t.Entry_By
 	          ,t.Comment_Id
 	          ,t.Array_Id
 	          ,t.Event_Id
 	          ,t.Locked
 	          ,Alarm_Id = ISNULL(a.Alarm_Id,0), Alarm_Start_Time = a.Start_Time
 	          ,Alarm_End_Time = a.End_Time, Alarm_Desc = a.Alarm_Desc
 	          ,Has_History = Case When Count(th.Test_Id) > 1 then 1 else 0 end
 	   FROM @Vars v 
 	   join Tests t on t.var_id = v.var_id 
 	   left Outer Join @Alarms a on a.Key_Id = t.Var_Id and
 	                                t.Result_On >= a.Start_Time and
 	                               (t.Result_On < a.End_time or a.End_Time is Null)                          
 	   --left Outer Join Test_History th on @ShowTestHistory = 1 and th.Test_Id = t.Test_Id and th.Entry_By not in (5)
 	   left Outer Join Test_History th on th.Test_Id = t.Test_Id and th.Entry_By not in (5) -- MKW 2006/11/02
 	   WHERE 	 t.Result_On = @Result_On
 	  	  	 AND v.Var_Id > 0 	  	  	 -- MKW 2006/11/02 - Hints a clustered index seek
 	       Group By v.Var_Id,t.Test_Id,t.Canceled,t.Result_On,t.Entry_On,t.Entry_By,t.Comment_Id,t.Array_Id,t.Event_Id,
 	          t.Var_Id,t.Locked,t.Result, ISNULL(a.Alarm_Id,0), a.Start_Time, a.End_Time, a.Alarm_Desc, v.Data_Type_Id
 	 END
  ELSE
 	 BEGIN
 	   -- Select Result Information.
 	   SELECT v.Var_Id
 	          ,t.Test_Id
 	          ,t.Var_Id
 	          ,t.Result_On
 	          ,t.Canceled
 	          ,Result = CASE 
 	                         WHEN @DecimalSep <> '.' and v.Data_Type_Id = 2 THEN REPLACE(T.Result, '.', @DecimalSep)
 	                         ELSE T.Result
 	                       END
 	          ,t.Entry_On
 	          ,t.Entry_By
 	          ,t.Comment_Id
 	          ,t.Array_Id
 	          ,t.Event_Id
 	          ,t.Locked
 	          ,Alarm_Id = ISNULL(a.Alarm_Id,0), Alarm_Start_Time = a.Start_Time
 	          ,Alarm_End_Time = a.End_Time, Alarm_Desc = a.Alarm_Desc
 	          ,Has_History = 0
 	   FROM @Vars v 
 	   join Tests t on t.var_id = v.var_id 
 	   left Outer Join @Alarms a on a.Key_Id = t.Var_Id and
 	                                t.Result_On >= a.Start_Time and
 	                               (t.Result_On < a.End_time or a.End_Time is Null)                          
 	   WHERE 	 t.Result_On = @Result_On
 	  	  	 AND v.Var_Id > 0 	  	  	 -- MKW 2006/11/02 - Hints a clustered index seek
 	 END
-- Return resultset [#5/5] - 0 if OK to process alarms, 1 if too many
  Select @TooManyAlarms as TooManyAlarms
RETURN(100)
