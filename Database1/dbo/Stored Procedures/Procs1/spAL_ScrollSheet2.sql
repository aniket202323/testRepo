CREATE Procedure dbo.spAL_ScrollSheet2
  @Sheet_Desc nvarchar(50),
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
          @Sheet_Type int,
          @PEI_Id int
  -- Get general sheet information.
  SELECT @Sheet_Id = Sheet_Id,
         @Event_Type = Event_Type,
         @Interval = Interval,
         @Offset = Offset,
         @MasterUnit = Master_Unit,
         @Sheet_Type = Sheet_Type,
         @PEI_Id = PEI_Id
    FROM Sheets
    WHERE (Sheet_Desc = @Sheet_Desc)
  -- Determine whether or not to retrieve alarm infomation
  SELECT @GetAlarms = Coalesce(Value, 0) From Sheet_Display_Options Where Display_option_id = 164 and Sheet_Id = @Sheet_id
  -- Create temporary table containing all the variables on named sheet.
  Declare @Var Table(
         Var_Id int,
         Var_Order int,
         PU_Id int
  	    	    	    	   )
  Insert into @Var (Var_Id, Var_Order, PU_Id)
  SELECT sv.Var_Id, sv.Var_Order, v.PU_Id
    FROM Sheet_Variables sv
    JOIN Variables_Base v on v.Var_id = sv.Var_Id
    WHERE (sv.Sheet_Id = @Sheet_Id)
    ORDER BY sv.Var_Order
  -- Create a temporary table containing the specific times (columns) on the sheet. The method used
  -- to construnct this temporary table will vary according to sheet type (e.g. event-, time-, or
  -- interval-based sheets).
  Declare @Col Table(
         Result_On datetime,
         Event_Id int,
         Event_Num nvarchar(25),
         Event_Status int,
         Comment_Id int,
         Applied_Product int,
         PU_Id int,
         Conformance tinyint,
         Testing_Prct_Complete tinyint,
         User_Signoff_Id int,
         Approver_User_Id int,
         User_Reason_Id int,
         Approver_Reason_Id int,
         Source_Event_Id int,
         Source_Event_Num nvarchar(25), 
         Component_Id int,
         Acknowledged tinyint,
         TestingStatus 	  	 int
          )
  If @Sheet_Type = 2  --Event based Autolog
    Begin
  	    	    Insert into @Col (Result_On,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,PU_Id,Conformance,
  	    	                      Testing_Prct_Complete,User_Signoff_Id,Approver_User_Id,User_Reason_Id,Approver_Reason_Id,
                        Source_Event_Id, Source_Event_Num, Component_Id,Acknowledged,TestingStatus)
  	    	    	    SELECT TimeStamp,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,PU_Id,Conformance,Testing_Prct_Complete,
  	    	    	           Coalesce(User_Signoff_Id, 0),Coalesce(Approver_User_Id, 0),Coalesce(User_Reason_Id, 0),Coalesce(Approver_Reason_Id, 0),
  	    	    	           Null,Null,Null,0,coalesce(testing_status,1)
  	    	    	      FROM Events
  	    	    	      WHERE (@Event_Type = 1) AND
  	    	    	            (Pu_Id = @MasterUnit) AND
  	    	    	            (TimeStamp >= @Start_Time) AND
  	    	    	            (TimeStamp <=  @End_Time)
          ORDER BY TimeStamp DESC
    End
  Else
    If @Sheet_Type = 19 --Event Component Autolog
      Begin
 	  	 DECLARE @EVENTCOMPONENTS Table (Component_Id 	 int,
 	  	  	  	  	  	  	  	  	  	 Result_On 	  	 DateTime,
 	  	  	  	  	  	  	  	  	  	 Event_Id 	  	 int,
 	  	  	  	  	  	  	  	  	  	 Source_Event_Id int,
 	  	  	  	  	  	  	  	  	  	 PEI_ID 	  	  	 int)
/* All Components for this pei + unknown pei*/
 	  	 INSERT INTO @EVENTCOMPONENTS (Component_Id,Result_On,Event_Id,Source_Event_Id,PEI_ID)
 	  	  	 SELECT Distinct ec.Component_Id,ec.TimeStamp, ec.Event_Id,ec.Source_Event_Id,ec.PEI_ID
 	  	  	  	 FROM Event_Components ec
 	  	  	  	 Where ec.TimeStamp >= @Start_Time and ec.TimeStamp <= @End_Time and (ec.PEI_Id = @PEI_Id or ec.PEI_Id is null)
/* Check Input history table for unknown pei */
 	  	 IF EXISTS(Select * From @EVENTCOMPONENTS Where PEI_ID Is NULL)
 	  	 BEGIN
 	  	  	 Update @EVENTCOMPONENTS Set PEI_ID = ih.PEI_Id
 	  	  	  	 FROM @EVENTCOMPONENTS a
 	  	  	  	 JOIN PrdExec_Input_Event_History ih on ih.event_Id = a.Source_Event_Id
 	  	  	  	 WHERE a.PEI_Id IS NULL
 	  	 END
/* last attempt - by source input for unknown pei */
 	  	 IF EXISTS(Select * From @EVENTCOMPONENTS Where PEI_ID Is NULL)
 	  	 BEGIN
 	  	  	 Update @EVENTCOMPONENTS Set PEI_ID = peis.PEI_Id
 	  	  	  	 FROM @EVENTCOMPONENTS a
 	  	  	  	 JOIN Events e on e.event_Id = a.Source_Event_Id
 	  	  	  	 Join PrdExec_Input_Sources peis ON peis.PEI_Id = @PEI_Id and peis.pu_Id = e.PU_Id
 	  	  	  	 WHERE a.PEI_Id IS NULL
 	  	 END
 	  	 DELETE FROM @EVENTCOMPONENTS WHERE PEI_ID <> @PEI_Id OR PEI_ID Is NULL
 	  	 Insert into @Col (Component_Id,Result_On,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,PU_Id,Conformance,
 	  	  	  	  	  	  	 Testing_Prct_Complete,User_Signoff_Id,Approver_User_Id,User_Reason_Id,Approver_Reason_Id,
 	  	  	  	  	  	  	 Source_Event_Id, Source_Event_Num)
 	  	  	 SELECT Distinct ec.Component_Id,ec.Result_On, e.Event_Id,e.Event_Num,e.Event_Status,e.Comment_Id,e.Applied_Product,e.PU_Id,e.Conformance,
 	  	  	  	  	  	  	 e.Testing_Prct_Complete,Coalesce(e.User_Signoff_Id, 0), Coalesce(e.Approver_User_Id, 0),Coalesce(e.User_Reason_Id, 0),
 	  	  	  	  	  	 Coalesce(e.Approver_Reason_Id, 0), e1.Event_Id, e1.Event_Num
 	  	 From @EVENTCOMPONENTS ec
 	  	 Join Events e on e.Event_Id = ec.Event_Id
 	  	 Join Events e1 on e1.Event_Id = ec.Source_Event_Id
           ORDER BY ec.Result_On DESC, ec.Component_Id
      End
    Else
      Begin
  	        --Time based or Product/Time Autolog
  	    	    	    Insert into @Col (Result_On,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,PU_Id,Conformance,
  	    	    	                      Testing_Prct_Complete,User_Signoff_Id,Approver_User_Id,User_Reason_Id,Approver_Reason_Id,
                          Source_Event_Id, Source_Event_Num, Component_Id)
  	    	    	    SELECT Result_On, 0, NULL, Null, Comment_Id, Null, Null, Null, Null, Coalesce(User_Signoff_Id, 0), Coalesce(Approver_User_Id, 0),
  	    	    	           Coalesce(User_Reason_Id, 0),Coalesce(Approver_Reason_Id, 0), Null, Null, Null
  	    	    	      FROM Sheet_Columns
  	    	    	      WHERE (@Event_Type = 0) AND
  	    	    	            (Sheet_Id = @Sheet_Id) AND
  	    	    	            (Result_On >= @Start_Time) AND
  	    	    	            (Result_On <= @End_Time)
  	    	    	      ORDER BY Result_On DESC
  	    	    	  End
--Update Desc from User Defined Events table
  If @Sheet_Type = 25
    Begin
      Declare @PU_Id int, @EventSubtypeId Int
      Select @PU_Id = Master_Unit, @EventSubtypeId = Event_Subtype_Id From Sheets Where Sheet_Desc = @Sheet_Desc
      Update @Col Set Event_Num = substring(UDE_Desc,1,25)
 	  	  	  	  	 ,Event_Id = ude.UDE_Id
 	  	  	  	  	 ,Event_Status = ude.Event_Status
 	  	  	  	  	 ,Conformance = ude.Conformance
 	  	  	  	  	 ,Testing_Prct_Complete = ude.Testing_Prct_Complete
 	  	  	  	  	 ,Acknowledged = coalesce(ude.ack,0)
 	  	  	  	  	 ,TestingStatus = coalesce(ude.Testing_Status,1)
        From User_Defined_Events ude
          Where ude.PU_Id = @PU_Id and ude.End_Time = Result_On and ude.Event_Subtype_Id = @EventSubtypeId
    End
  -- Remember the number of rows obtained.
  SELECT @RowsFound = @@ROWCOUNT
  Declare  @Alarms Table(
    Alarm_Id int,
    Start_Time datetime,
    End_Time datetime,
    Alarm_Desc nvarchar(1000),
    Key_Id int
    )
  If @GetAlarms <> 0
    BEGIN
      -- Create temporary table containing all the alarms for variables on this sheet
      Insert Into @Alarms
        SELECT a.Alarm_Id, a.Start_Time, a.End_Time, a.Alarm_Desc, a.Key_Id
          FROM Alarms a
          join @Var v on v.var_id = a.key_Id
           Where (a.End_Time >= @Start_Time or a.End_Time is Null) and a.Alarm_Type_Id in (1,2,4)
    END
  Select @TooManyAlarms = 0
  If (Select Count(*) From @Alarms) > 1000
    Begin
      Select @TooManyAlarms = 1
      Delete From @Alarms
    End
  -- Create temporary table containing all the tests on the named sheet at given times.
  Declare  @Tst Table(
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
  Insert into @Tst (Test_Id,Canceled,Result_On,Entry_On,Entry_By,Comment_Id,Array_Id,Event_Id,
                    Var_Id,Locked,Result,Second_User_Id,PU_Id,Alarm_Id,Alarm_Start_Time,Alarm_End_Time,Alarm_Desc,Has_History)
  SELECT t.Test_Id,t.Canceled,t.Result_On,t.Entry_On,t.Entry_By,t.Comment_Id,t.Array_Id,t.Event_Id,
         t.Var_Id,t.Locked,t.Result,t.Second_User_Id, v.PU_Id, Coalesce(a.Alarm_Id,0), a.Start_Time, 
         a.End_Time, a.Alarm_Desc, Case When Count(th.Test_Id) > 1 then 1 else 0 end
    FROM Tests t 
    join @Var v on v.var_id = t.var_id
    join @Col c on c.result_on = t.result_on
    left Outer Join @Alarms a on a.Key_Id = t.Var_Id and
                                t.Result_On >= a.Start_Time and
                               (t.Result_On < a.End_time or a.End_Time is Null)                          
    left Outer Join Test_History th on th.Test_Id = t.Test_Id and th.Entry_By <> 5
    Where t.result_on >= @Start_Time and t.result_on <= @End_Time
      Group By t.Test_Id,t.Canceled,t.Result_On,t.Entry_On,t.Entry_By,t.Comment_Id,t.Array_Id,t.Event_Id,
         t.Var_Id,t.Locked,t.Result,t.Second_User_Id, v.PU_Id, Coalesce(a.Alarm_Id,0), a.Start_Time, 
         a.End_Time, a.Alarm_Desc
  -- Return resultset [#1/4] indicating sheet information.
  SELECT Sheet_Id = @Sheet_Id,  	    	    	    	  -- sheet identifier
         Time_Count = (SELECT COUNT(*) FROM @Col)  	  -- number of distinct times
  -- Return resultset [#2/4] containing distinct times.
  SELECT Result_On,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,PU_Id,Conformance,
  	    	    	     Testing_Prct_Complete,User_Signoff_Id,Approver_User_Id,User_Reason_Id,Approver_Reason_Id,
         Source_Event_Id, Source_Event_Num, Component_Id,Acknowledged,TestingStatus 
    FROM @Col c
    ORDER BY Result_On
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
   T.Has_History,
   Result = CASE 
              WHEN @DecimalSep <> '.' and V.Data_Type_Id = 2 THEN REPLACE(T.Result, '.', @DecimalSep)
              ELSE T.Result
              END
    FROM @Tst T
    JOIN Variables_Base v on t.Var_Id = v.Var_Id
-- Return resultset [#4/4] - 0 if OK to process alarms, 1 if too many
  Select @TooManyAlarms as TooManyAlarms
