-- spXLA_TestsDataByTestName_NoProduct ( mt/12-20-2004 )
-- MODIFICATION NOTE:
--     As of today client connection software will use SET NOCOUNT to determine _LOCAL / _GLOBAL for 
--     "Description" fields (Var_Desc, Prod_Desc, PU_Desc, etc) DO NOT use SET NOCOUNT in stored procedure.
--
-- ECR #25583: Given @Test_Name and @Start_Time and @End_Time, we want to return for all variables that belong to 
-- @Test_Name, e.Event_Num, v.Master_Unit, e.timeStamp, t.Result
--
-- ECR #29677: mt/5-3-2005 -- added Var_Desc as additional sort criteria to the return result set.
-- ECR #34381 sb/9-15-2007:  Tests returned should be start_time<timestamp<=end_time
CREATE PROCEDURE dbo.spXLA_TestsDataByTestName_NoProduct
      @Test_Name            Varchar(50)
 	 , @Start_Time 	  	 DateTime
 	 , @End_Time 	  	 DateTime
    , @Crew_Desc            Varchar(10)
    , @Shift_Desc           Varchar(10)
    , @TimeSort             TinyInt
 	 , @DecimalChar 	  	 Varchar(1) = NULL --Comma Or Period (Default) to accommodate different regional setttings on PC --mt/2-6-2002
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
If @DecimalChar Is NULL SELECT @DecimalChar = '.' 	 --Set Decimal Separator Default Value, if applicable
CREATE TABLE #VariablesAndEvents ( Master_Unit Int, PU_Id Int, Var_Id Int, Var_Desc Varchar(50), Data_Type_Id Int
                                 , Event_Num Varchar(50), Event_Id Int, Event_Type Int, Event_Status Int, TimeStamp DateTime )
-- Get the variables that belong to Test_Name and related events into temp table
--------------------------------------------------------------------------------
  INSERT 
    INTO #VariablesAndEvents ( Master_Unit, PU_Id, Var_Id, Var_Desc, Data_Type_Id, Event_Num, Event_Id, Event_Type, Event_Status, TimeStamp )
  SELECT COALESCE( pu.Master_Unit, v.PU_Id ), v.PU_Id, v.Var_Id, v.Var_Desc, v.Data_Type_Id, e.Event_Num, e.Event_Id, e.Event_Subtype_Id, e.Event_Status, e.TimeStamp
    FROM Variables v 
    JOIN Events e ON e.PU_Id = v.PU_Id AND e.TimeStamp > @Start_Time AND e.TimeStamp <= @End_Time
    JOIN Prod_Units pu ON pu.PU_Id = v.PU_Id
   WHERE v.Test_Name = @Test_Name /* AND v.Data_Type_Id <= 2 */ AND v.Event_Type = 1 -- Event based, leave datatype open
--Note: PU_Id = 0 and PL_Id = 0 are invalid unit and line. We keep them in the database for cleanup purposes. 
  --    Whenever users decdided to obsolete variables, they will not be deleted from Tests table (performance issue) 
  --    but they will be assigned to the deleted PU_Id instead.
DELETE FROM #VariablesAndEvents WHERE PU_Id = 0
-- Determine Crew,Shift Type
----------------------------
If      @Crew_Desc Is NULL AND @Shift_Desc Is NULL     GOTO NOCREW_NOSHIFT_NOPRODUCT_RESULTSET
Else If @Crew_Desc Is NOT NULL AND @Shift_Desc Is NULL GOTO HASCREW_NOSHIFT_NOPRODUCT_RESULTSET
Else If @Crew_Desc Is NULL AND @Shift_Desc Is NOT NULL GOTO NOCREW_HASSHIFT_NOPRODUCT_RESULTSET
Else                                                   GOTO HASCREW_HASSHIFT_NOPRODUCT_RESULTSET
--EndIf:Crew,Shift
NOCREW_NOSHIFT_NOPRODUCT_RESULTSET:
  If @TimeSort = 1
  BEGIN
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone, [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone, t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         Left JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id
 	  	  JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
     ORDER BY t.Result_On ASC, ve.Var_Desc ASC 	  	  	 -- ECR #29677
  end
  Else
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone, [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone, t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         Left JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id
 	  	  JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
     ORDER BY t.Result_On DESC, ve.Var_Desc DESC 	  	 -- ECR #29677
  --EndIf
  GOTO DROP_TEMP_TABLES
--End NOCREW_NOSHIFT_NOPRODUCT_RESULTSET:
HASCREW_NOSHIFT_NOPRODUCT_RESULTSET:
  If @TimeSort = 1
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone, [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone, t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Crew_Desc = @Crew_Desc
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
     ORDER BY t.Result_On ASC, ve.Var_Desc ASC 	  	  	 -- ECR #29677
  Else
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone, [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone, t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Crew_Desc = @Crew_Desc
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
     ORDER BY t.Result_On DESC, ve.Var_Desc DESC 	  	 -- ECR #29677
  --EndIf
  GOTO DROP_TEMP_TABLES
--End HASCREW_NOSHIFT_NOPRODUCT_RESULTSET:
NOCREW_HASSHIFT_NOPRODUCT_RESULTSET:
  If @TimeSort = 1
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone, [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone, t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Shift_Desc = @Shift_Desc
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
     ORDER BY t.Result_On ASC, ve.Var_Desc ASC 	  	  	 -- ECR #29677
  Else
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone, [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone, t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Shift_Desc = @Shift_Desc
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
     ORDER BY t.Result_On DESC, ve.Var_Desc DESC 	  	 -- ECR #29677
--EndIf
  GOTO DROP_TEMP_TABLES
--End NOCREW_HASSHIFT_NOPRODUCT_RESULTSET:
HASCREW_HASSHIFT_NOPRODUCT_RESULTSET:
  If @TimeSort = 1
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone, [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone, t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
     ORDER BY t.Result_On ASC, ve.Var_Desc ASC 	  	  	 -- ECR #29677
  Else
       SELECT pl.PL_Desc, [Master_Unit] = pu.PU_Desc, pu2.PU_Desc, ve.Event_Num, ve.Event_Id, ve.Var_Desc, ve.Var_Id
            , [Result] = Case When @DecimalChar <> '.' AND ve.Data_Type_Id = 2 Then REPLACE( t.Result, '.', @DecimalChar ) Else t.Result End
            , Event_Status = s.ProdStatus_Desc, ve.Data_Type_Id, et.ET_Desc
            , [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone, [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone, t.Canceled, t.Comment_Id, C.Crew_Desc, C.Shift_Desc
         FROM Tests t
         JOIN #VariablesAndEvents ve ON ve.Var_Id = t.Var_Id AND ve.TimeStamp = t.Result_ON AND t.Canceled = 0
         JOIN Crew_Schedule C ON C.Start_Time < ve.TimeStamp AND C.End_Time >= ve.TimeStamp AND C.PU_Id = ve.PU_Id AND C.Crew_Desc = @Crew_Desc AND C.Shift_Desc = @Shift_Desc
         JOIN Prod_Units pu ON pu.PU_Id = ve.Master_Unit
         JOIN Prod_Units pu2 ON pu2.PU_Id = ve.PU_Id
         JOIN Prod_Lines pl ON pl.PL_Id = pu.PL_Id
         LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = ve.Event_Status
         LEFT OUTER JOIN Event_Types et ON et.ET_Id = ve.Event_Type
     ORDER BY t.Result_On DESC, ve.Var_Desc DESC 	  	 -- ECR #29677
  --EndIf
  GOTO DROP_TEMP_TABLES
--END HASCREW_HASSHIFT_NOPRODUCT_RESULTSET:
DROP_TEMP_TABLES:
  DROP TABLE  #VariablesAndEvents  
  GOTO EXIT_PROCEDURE
EXIT_PROCEDURE:
