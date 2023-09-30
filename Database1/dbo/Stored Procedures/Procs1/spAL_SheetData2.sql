CREATE PROCEDURE dbo.spAL_SheetData2 
  @Sheet_Desc nvarchar(50),
  @Start_Time datetime ,
  @DecimalSep char(1) = '.'
AS 
--JG Added this for regional settings:
--  Must replace the period in the result value with a comma if the 
--  passed decimal separator is not a period.
Select @DecimalSep = COALESCE(@DecimalSep,'.')
--JG END
  -- Declare local variables.
  DECLARE @Sheet_id int,
  	    @Sheet_Com_Id int,
          @Event_Type tinyint,
          @Interval smallint,
          @Offset smallint,
          @Initial_Count int,
          @Maximum_Count int,
          @RowsFound int,
          @MasterUnit int,
          @RCount int,
          @GetAlarms int,
          @TooManyAlarms tinyint,
          @Sheet_Type int,
          @PEI_Id int
  -- Get general sheet information.
  SELECT @Sheet_Id = Sheet_Id,
         @Event_Type = Event_Type,
         @Interval = Interval,
         @Offset = Offset,
         @Initial_Count = Initial_Count,
         @Maximum_Count = Maximum_Count,
         @MasterUnit = Master_Unit,
  	    	    	    	   @Sheet_Com_Id = Comment_Id,
         @Sheet_Type = Sheet_Type,
         @PEI_Id = PEI_Id
    FROM Sheets
    WHERE (Sheet_Desc = @Sheet_Desc)
  -- Determine whether or not to retrieve alarm infomation
  SELECT @GetAlarms = Coalesce(Value, 0) From Sheet_Display_Options Where Display_option_id = 164 and Sheet_Id = @Sheet_id
  Declare @Var Table (
         Var_Id int,
         Var_Order int,
         Title nvarchar(100),
         PU_Id int,
         Spec_Id int,
         DS_Id int
         )
  -- Create temporary table containing all the variables on named sheet.
  Insert into @Var (Var_Id, Var_Order, Title, PU_Id, Spec_Id, DS_Id)
  SELECT sv.Var_Id, sv.Var_Order, sv.Title, v.PU_Id, v.Spec_Id, ds.DS_Id
    FROM Sheet_Variables sv
    left outer join Variables_Base v on v.var_id = sv.var_id 
    left outer join Data_Source ds on ds.ds_id = v.ds_id
    WHERE (sv.Sheet_Id = @Sheet_Id) 
    ORDER BY sv.Var_Order
  Declare  @Col Table(
         Result_On datetime,
         Event_Id int,
         Event_Num nvarchar(50),
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
         Source_Event_Num nvarchar(50),
         Component_Id int,
         Acknowledged tinyint,
         TestingStatus 	  	 int
          )
  If @Sheet_Type = 2 --Event based Autolog
    Begin
  	    	    Insert into @Col (Component_Id,Result_On,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,PU_Id,Conformance,
  	    	                      Testing_Prct_Complete,User_Signoff_Id,Approver_User_Id,User_Reason_Id,Approver_Reason_Id,
                        Source_Event_Id, Source_Event_Num,Acknowledged,TestingStatus)
  	    	    SELECT Null,TimeStamp, Event_Id, Event_Num, Event_Status, Comment_Id, Applied_Product, PU_Id, Conformance,
  	    	    	    	    	    	   Testing_Prct_Complete,Coalesce(User_Signoff_Id, 0), Coalesce(Approver_User_Id, 0),Coalesce(User_Reason_Id, 0),
  	    	           Coalesce(Approver_Reason_Id, 0), Null, Null,0,Coalesce(Testing_Status,1) 
  	    	      FROM Events
  	    	      WHERE (@Event_Type = 1) AND
  	    	            (Pu_Id = @MasterUnit) AND
  	    	            (TimeStamp >= @Start_Time)
  	    	      ORDER BY TimeStamp DESC
    End
  Else
    If @Sheet_Type = 19 --Event-Component Autolog
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
 	  	  	  	 Where ec.TimeStamp >= @Start_Time and (ec.PEI_Id = @PEI_Id or ec.PEI_Id is null)
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
 	  	  	  	  	  	  	 Source_Event_Id, Source_Event_Num,Acknowledged)
 	  	  	 SELECT Distinct ec.Component_Id,ec.Result_On, e.Event_Id,e.Event_Num,e.Event_Status,e.Comment_Id,e.Applied_Product,e.PU_Id,e.Conformance,
 	  	  	  	  	  	  	 e.Testing_Prct_Complete,Coalesce(e.User_Signoff_Id, 0), Coalesce(e.Approver_User_Id, 0),Coalesce(e.User_Reason_Id, 0),
 	  	  	  	  	  	 Coalesce(e.Approver_Reason_Id, 0), e1.Event_Id, e1.Event_Num,0
 	  	 From @EVENTCOMPONENTS ec
 	  	 Join Events e on e.Event_Id = ec.Event_Id
 	  	 Join Events e1 on e1.Event_Id = ec.Source_Event_Id
           ORDER BY ec.Result_On DESC, ec.Component_Id
      End
    Else
      Begin
  	        --Time based or Product/Time Autolog
  	    	    	    Insert into @Col (Component_Id,Result_On,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,PU_Id,Conformance,
  	    	    	                      Testing_Prct_Complete,User_Signoff_Id,Approver_User_Id,User_Reason_Id,Approver_Reason_Id,
                          Source_Event_Id, Source_Event_Num,Acknowledged)
  	    	    	    SELECT Null, Result_On, 0, NULL, Null, Comment_Id, Null, Null, Null, Null, Coalesce(User_Signoff_Id, 0), Coalesce(Approver_User_Id, 0),
  	    	    	           Coalesce(User_Reason_Id, 0),Coalesce(Approver_Reason_Id, 0), Null, Null,0
  	    	    	      FROM Sheet_Columns
  	    	    	      WHERE (@Event_Type = 0) AND
  	    	    	            (Sheet_Id = @Sheet_Id) AND
  	    	    	            (Result_On >= @Start_Time)
  	    	    	      ORDER BY Result_On DESC
      End
--Update Desc from User Defined Events table
  If @Sheet_Type = 25
    Begin
      Declare @PU_Id int, @EventSubtypeId Int
      Select @PU_Id = Master_Unit, @EventSubtypeId = Event_Subtype_Id From Sheets Where Sheet_Desc = @Sheet_Desc
    Update @Col set Event_Num = substring(ude.UDE_Desc,1,50), Event_Id = ude.UDE_Id,Event_Status = ude.Event_Status,
 	  	 Conformance = ude.Conformance,Testing_Prct_Complete = ude.Testing_Prct_Complete,Acknowledged = coalesce(ude.ack,0),TestingStatus = coalesce(ude.Testing_Status,1)
        From User_Defined_Events ude
 	  	 JOIN Sheets s ON s.Sheet_Id = @Sheet_Id
 	  	  	  	  	 AND 	 s.Master_Unit = ude.PU_Id
 	  	  	  	  	 AND 	 s.Event_Subtype_Id = ude.Event_Subtype_Id
          Where ude.End_Time = Result_On
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
        Where a.End_Time >= @Start_Time or a.End_Time is Null and a.Alarm_Type_Id in (1,2,4)
    END
  Select @TooManyAlarms = 0
  If (Select Count(*) From @Alarms) > 1000
    Begin
      Select @TooManyAlarms = 1
      Delete From @Alarms
    End
  -- Create temporary table containing all the tests on the named sheet at given times.
  Declare @Tst Table(
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
         a.End_Time, a.Alarm_Desc, 0 --Case When Count(th.Test_Id) > 1 then 1 else 0 end
    FROM Tests t 
    join @Var v on v.var_id = t.var_id
    join @Col c on c.result_on = t.result_on
    left Outer Join @Alarms a on a.Key_Id = t.Var_Id and
                                t.Result_On >= a.Start_Time and
                               (t.Result_On < a.End_time or a.End_Time is Null)                          
--    left outer join Test_History th on th.Test_Id = t.Test_Id and th.Entry_By <> 5
    Where t.result_on >= @Start_Time
      Group By t.Test_Id,t.Canceled,t.Result_On,t.Entry_On,t.Entry_By,t.Comment_Id,t.Array_Id,t.Event_Id,
         t.Var_Id,t.Locked,t.Result,t.Second_User_Id, v.PU_Id, Coalesce(a.Alarm_Id,0), a.Start_Time, 
         a.End_Time, a.Alarm_Desc
 	 Declare @Hist Table (test_id Bigint,MyCount int)
 	 Insert Into @Hist(test_id,MyCount)
 	  	 SELECT a.test_id,count(*)
 	  	 FROM Test_History a
 	  	 Join @Tst b On b.Test_Id = a.Test_Id
 	  	 WHERE a.entry_by <> 5
 	  	 GROUP BY a.test_id
 	  	 Having Count(*) > 1
 	 Update @Tst  set Has_History = 1
 	 FRoM @Tst a
 	 Join @Hist b on a.test_id = b.test_id
-- Return resultset [#1/5] indicating sheet information.
  SELECT Sheet_Id = @Sheet_Id,  	    	    	    	  -- sheet identifier
         Var_Count = (SELECT COUNT(*) FROM @Var),  	  -- number of variables
         Time_Count = (SELECT COUNT(*) FROM @Col),  	  -- number of distinct times
         Event_Type = @Event_Type,  	    	  -- is sheet event based
         Interval = @Interval,  	    	    	    	  -- interval
         Offset = @Offset,  	    	    	    	  -- offset
  	    	    	     	   CommentID = @Sheet_Com_Id  	    	  -- Comment Id for Sheet
 -- Return resultset [#2/5] containing distinct times.
  SELECT Result_On,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,PU_Id,Conformance,
         Testing_Prct_Complete,User_Signoff_Id,Approver_User_Id,User_Reason_Id,Approver_Reason_Id,
         Source_Event_Id, Source_Event_Num, Component_Id,Acknowledged,TestingStatus 
    FROM @Col c
    ORDER BY c.Result_On
  -- Return resultset [#3/5] containing variable-specific information.
  Declare @DisplayvarDesc int
  --Change display_option_id value before checkin
  SET @DisplayVarDesc = (SELECT Coalesce(value,0) FROM dbo.sheet_display_options where Display_option_id = 458 and sheet_id = @Sheet_Id)
  SELECT v2.Var_Order,
         DS.DS_Desc,
         v2.Title,
  	   Write_Access =
           CASE
             WHEN (v2.DS_Id = 2) Or (v2.DS_Id = 16) THEN 1
             ELSE 0
           END,
         v.Data_Type_Id,
         dt.Data_Type_Desc,
  	   Var_Precision = 
             CASE 
               WHEN v.Var_Precision Is Null THEN 0
               ELSE v.Var_Precision
             END,
         Spec_Id = 
             CASE 
               WHEN v.Spec_Id Is Null THEN 0
               ELSE v.Spec_Id
             END,
         Spec_Desc = 
             CASE 
               WHEN v.Spec_Id Is Null THEN ''
               ELSE (select spec_desc from specifications where Spec_Id = v.Spec_Id)
             END,
         Spec_Comment = 
             CASE 
               WHEN v.Spec_Id Is Null THEN 0
               ELSE (select comment_id from specifications where Spec_Id = v.Spec_Id)
             END,
         pl.PL_Id,
         pl.PL_Desc,
         Line_Comment = 
  	        CASE
  	    	  WHEN pl.comment_id Is Null THEN 0 ELSE pl.comment_id
  	        END,
         pu.PU_Id,
  	      pu.PU_Desc,
         Unit_Comment = 
  	        CASE
  	    	  WHEN pu.comment_id Is Null THEN 0 ELSE pu.comment_id
  	        END,
         v2.Var_Id,
         Var_Desc = 
 	  	  CASE WHEN @DisplayVarDesc = 0 THEN v.var_desc
 	  	  WHEN @DisplayVarDesc = 1 and v.User_defined1 is not null THEN v.User_defined1
 	  	   WHEN @DisplayVarDesc = 2 and v.User_defined2 is not null THEN v.User_defined2
 	  	    WHEN @DisplayVarDesc = 3 and v.User_defined3 is not null THEN v.User_defined3
 	  	    ELSE v.var_desc
 	  	    END ,
         Var_Comment = 
  	        CASE
  	    	  WHEN v.comment_id Is Null THEN 0 ELSE v.comment_id
  	        END,
         v.Eng_Units,
  	      v.group_id,
         pu.master_unit, 
         v.input_tag,
         v.output_tag,
         v.sa_id, 
         v.external_link,
         v.sampling_interval,
         v.force_sign_entry, 
         v.ESignature_Level,
         v.SPC_Calculation_Type_Id,
         v.String_Specification_Setting,
         v.PVar_Id,
         Is_Calculation = 
  	        CASE
  	    	  WHEN v.Calculation_ID Is Null THEN 0 ELSE 1
  	        END,
 	     SpecCount = Count(vs.Var_Id)
 	  	 ,v.Is_Active
    FROM @Var v2
    left outer join Variables v on v.Var_Id = v2.Var_Id 
    left outer join Prod_Units pu on pu.pu_id = v2.PU_Id
    left outer join Prod_Lines pl on pl.pl_id = pu.pl_id
    left outer join Data_Source ds on ds.DS_Id = v2.DS_id
    left outer join Var_Specs vs on vs.Var_Id = v.Var_Id
    left outer join Data_Type dt on v.Data_Type_Id = dt.Data_Type_Id
    Group By v2.Var_Order, ds.DS_Desc, v2.Title, v2.DS_Id, v.Data_Type_Id, v.Var_Precision, 
 	 v.Spec_Id, pl.PL_Id, pl.PL_Desc, pl.Comment_Id, pu.PU_Id, pu.PU_Desc, pu.Comment_Id, 
 	 v.Var_Id, v.Is_Active,
 	 --v.Var_Desc,
 	  CASE WHEN @DisplayVarDesc = 0 THEN v.var_desc
 	  	  WHEN @DisplayVarDesc = 1 and v.User_defined1 is not null THEN v.User_defined1
 	  	   WHEN @DisplayVarDesc = 2 and v.User_defined2 is not null THEN v.User_defined2
 	  	    WHEN @DisplayVarDesc = 3 and v.User_defined3 is not null THEN v.User_defined3
 	  	    ELSE v.var_desc END,
 	  v2.Var_Id, v.Comment_Id, v.Eng_Units, v.Group_Id, pu.Master_Unit, 
 	 v.Input_Tag, v.Output_Tag, v.SA_Id, v.External_Link, 
 	 v.Sampling_Interval, v.Force_Sign_Entry, v.Esignature_Level, 
 	 v.SPC_Calculation_Type_Id, v.String_Specification_Setting, 
 	 v.PVar_Id, v.Calculation_Id, dt.Data_Type_Desc
    ORDER BY v2.Var_Order ASC
   Declare  @Enum Table(
         Data_Type_Id int,
         Phrase_Value varchar(25),
         Phrase_Order smallint,
         Comment_Required bit
         )
  Insert into @Enum (Data_type_id, phrase_value, phrase_order, comment_required)
  Select Distinct p.Data_type_id, p.phrase_value, p.phrase_order, p.comment_required
  	  from @Var v2 
 	  join variables_Base v on v2.var_id = v.var_id
  	  join phrase p on p.data_type_id = v.data_type_id
  	  where v.data_type_id > 5 and p.active = 1
  	  order by p.data_type_id, p.phrase_order, p.phrase_value
  Select @rcount = @@rowcount
  -- Return resultset [#4/5] containing the phrase information
  Select *, rcount = @rcount from @Enum order by data_type_id, phrase_order, phrase_value
 -- Return resultset [#4/5] containing the test information.
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
   T.PU_Id,
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
  -- Drop the remaining temporary tables.
-- Return resultset [#5/5] - 0 if OK to process alarms, 1 if too many
  Select @TooManyAlarms as TooManyAlarms
