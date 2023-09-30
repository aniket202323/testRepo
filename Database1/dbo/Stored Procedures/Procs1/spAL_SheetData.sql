CREATE PROCEDURE dbo.spAL_SheetData 
  @Sheet_Desc nvarchar(50),
  @Start_Time datetime AS
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
          @Sheet_Type int
  -- Get general sheet information.
  SELECT @Sheet_Id = Sheet_Id,
         @Event_Type = Event_Type,
         @Interval = Interval,
         @Offset = Offset,
         @Initial_Count = Initial_Count,
         @Maximum_Count = Maximum_Count,
         @MasterUnit = Master_Unit,
 	  	  	  	  @Sheet_Com_Id = Comment_Id,
         @Sheet_Type = Sheet_Type
    FROM Sheets
    WHERE (Sheet_Desc = @Sheet_Desc)
  -- Create temporary table containing all the variables on named sheet.
  Create Table #Var (
         Var_Id int,
         Var_Order int,
         Title nvarchar(100),
         PU_Id int,
         Spec_Id int,
         DS_Id int
         )
  Insert into #Var (Var_Id, Var_Order, Title, PU_Id, Spec_Id, DS_Id)
  SELECT sv.Var_Id, sv.Var_Order, sv.Title, v.PU_Id, v.Spec_Id, ds.DS_Id
    FROM Sheet_Variables sv
    left outer join Variables v on v.var_id = sv.var_id 
    left outer join Data_Source ds on ds.ds_id = v.ds_id
    WHERE (sv.Sheet_Id = @Sheet_Id) and (sv.Var_Id is not NULL)  --Can not handle titles
    ORDER BY sv.Var_Order
  Create Table #Col (
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
         Approver_Reason_Id int
         )
  If @Sheet_Type = 2
    Begin
 	  	   Insert into #Col (Result_On,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,PU_Id,Conformance,
 	  	                     Testing_Prct_Complete,User_Signoff_Id,Approver_User_Id,User_Reason_Id,Approver_Reason_Id)
 	  	   SELECT TimeStamp, Event_Id, Event_Num, Event_Status, Comment_Id, Applied_Product, PU_Id, Conformance,
 	  	  	  	  	  	  Testing_Prct_Complete,Coalesce(User_Signoff_Id, 0), Coalesce(Approver_User_Id, 0),Coalesce(User_Reason_Id, 0),
 	  	          Coalesce(Approver_Reason_Id, 0)
 	  	     FROM Events
 	  	     WHERE (@Event_Type = 1) AND
 	  	           (Pu_Id = @MasterUnit) AND
 	  	           (TimeStamp >= @Start_Time)
 	  	     ORDER BY TimeStamp DESC
    End
  Else
    Begin
 	  	   Insert into #Col (Result_On,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,PU_Id,Conformance,
 	  	                     Testing_Prct_Complete,User_Signoff_Id,Approver_User_Id,User_Reason_Id,Approver_Reason_Id)
 	  	   SELECT Result_On, 0, NULL, Null, Comment_Id, Null, Null, Null, Null, Coalesce(User_Signoff_Id, 0), Coalesce(Approver_User_Id, 0),
 	  	          Coalesce(User_Reason_Id, 0),Coalesce(Approver_Reason_Id, 0)
 	  	     FROM Sheet_Columns
 	  	     WHERE (@Event_Type = 0) AND
 	  	           (Sheet_Id = @Sheet_Id) AND
 	  	           (Result_On >= @Start_Time)
 	  	     ORDER BY Result_On DESC
    End
  -- Remember the number of rows obtained.
  SELECT @RowsFound = @@ROWCOUNT
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
         PU_Id int
         )
  Insert into #Tst (Test_Id,Canceled,Result_On,Entry_On,Entry_By,Comment_Id,Array_Id,Event_Id,Var_Id,Locked,Result,Second_User_Id,PU_Id)
  SELECT t.Test_Id,t.Canceled,t.Result_On,t.Entry_On,t.Entry_By,t.Comment_Id,t.Array_Id,t.Event_Id,t.Var_Id,t.Locked,t.Result,t.Second_User_Id, v.PU_Id
    FROM Tests t 
    join #Var v on v.var_id = t.var_id
    join #Col c on c.result_on = t.result_on
    Where t.result_on >= @Start_Time
-- Return resultset [#1/4] indicating sheet information.
  SELECT Sheet_Id = @Sheet_Id, 	  	  	  	 -- sheet identifier
         Var_Count = (SELECT COUNT(*) FROM #Var), 	 -- number of variables
         Time_Count = (SELECT COUNT(*) FROM #Col), 	 -- number of distinct times
         Event_Type = @Event_Type, 	  	 -- is sheet event based
         Interval = @Interval, 	  	  	  	 -- interval
         Offset = @Offset, 	  	  	  	 -- offset
  	   	  	  	  CommentID = @Sheet_Com_Id 	  	 -- Comment Id for Sheet
 -- Return resultset [#2/4] containing distinct times.
  SELECT Result_On,Event_Id,Event_Num,Event_Status,Comment_Id,Applied_Product,PU_Id,Conformance,
         Testing_Prct_Complete,User_Signoff_Id,Approver_User_Id,User_Reason_Id,Approver_Reason_Id
    FROM #Col c
    ORDER BY c.Result_On
  -- Drop the temporary times table.
  DROP TABLE #Col
  -- Return resultset [#3/4] containing variable-specific information.
  SELECT #Var.Var_Order,
         DS.DS_Desc,
         #Var.Title,
 	  Write_Access =
           CASE
             WHEN (#Var.DS_Id = 2) Or (#Var.DS_Id = 16) THEN 1
             ELSE 0
           END,
         v.Data_Type_Id,
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
         #Var.Var_Id,
         v.Var_Desc,
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
         Is_Calculation = 
 	       CASE
 	  	 WHEN v.Calculation_ID Is Null THEN 0 ELSE 1
 	       END,
 	  	   v.Is_Active
    FROM #Var
    left outer join Variables v on v.Var_Id = #Var.Var_Id 
    left outer join Prod_Units pu on pu.pu_id = #Var.PU_Id
    left outer join Prod_Lines pl on pl.pl_id = pu.pl_id
    left outer join Data_Source ds on ds.DS_Id = #Var.DS_id
    ORDER BY #Var.Var_Order ASC
  Create Table #Enum (
         Data_Type_Id int,
         Phrase_Value nvarchar(25),
         Phrase_Order smallint
         )
  Insert into #Enum (Data_type_id, phrase_value, phrase_order)
  Select Distinct p.Data_type_id, p.phrase_value, p.phrase_order
 	 from #Var join variables v on #Var.var_id = v.var_id
 	 join phrase p on p.data_type_id = v.data_type_id
 	 where v.data_type_id > 5 and p.active = 1
 	 order by p.data_type_id, p.phrase_order, p.phrase_value
  Select @rcount = @@rowcount
  -- Return resultset [#4/5] containing the phrase information
  Select *, rcount = @rcount from #Enum
  -- Drop the temporaty variables table.
  DROP TABLE #Var
  DROP TABLE #Enum
 -- Return resultset [#4/4] containing the test information.
  SELECT Test_Id,Canceled,Result_On,Entry_On,Entry_By,Comment_Id,Array_Id,Event_Id,Var_Id,Locked,Result,Second_User_Id,PU_Id
    FROM #Tst
  -- Drop the remaining temporary tables.
  DROP TABLE #Tst
