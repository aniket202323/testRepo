-- DESCRIPTION: spXLA_BrowseTestsHistory. When  Tests.Result_On is changed Proficy keeps track of the history in Test_History table.
-- This stored procedure all users to obtain history of Tests' result for a given variable over a specified period of time. 
-- ECR #25128: mt/1-20-2004: 
-- ECR #34381: sb/9-15-2007:  Tests returned should be start_time<result_on<=end_time
--
CREATE PROCEDURE dbo.spXLA_BrowseTestsHistory
 	   @Var_Id 	 Integer
 	 , @Var_Desc 	 Varchar(50)
 	 , @Start_Time   DateTime
 	 , @End_Time     DateTime
 	 , @TimeSort 	 TinyInt = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Start_Time = @Start_Time at time zone @InTimeZone at time zone @DBTz 
SELECT @End_Time = @End_Time at time zone @InTimeZone at time zone @DBTz 
-- Set Default Sort Order
If @TimeSort Is NULL SELECT @TimeSort = 0
DECLARE @Data_Type_Id Int
DECLARE @Row_Count    Int
-- First Validate Variable Input to prevent possible duplicate variable descriptions
--
SELECT @Row_Count = 0
If @Var_Desc Is NULL AND @Var_Id Is NULL
  BEGIN
    SELECT [ReturnStatus] = -35 	  	 --No variable NOT SPECIFIED at all
    RETURN
  END
Else If @Var_Desc Is NULL -- we have Var_ID
  BEGIN
    SELECT @Var_Desc = v.Var_Desc, @Data_Type_Id = v.Data_Type_Id FROM Variables v WHERE v.Var_Id = @Var_Id
    SELECT @Row_Count = @@ROWCOUNT
    If @Row_Count = 0
      BEGIN
        SELECT [ReturnStatus] = -30 	 --Variable specified NOT FOUND
        RETURN
      END
    --EndIf:count = 0
  END
Else --we have Var_Desc
  BEGIN
    SELECT @Var_Id = v.Var_Id, @Data_Type_Id = v.Data_Type_Id FROM Variables v WHERE v.Var_Desc = @Var_Desc
    SELECT @Row_Count = @@ROWCOUNT
    If @Row_Count <> 1
      BEGIN
        If @Row_Count = 0
          SELECT [ReturnStatus] = -30 	 --variable specified NOT FOUND
        Else --too many Var_Desc
          SELECT [ReturnStatus] = -33 	 --DUPLICATE FOUND for Var_desc
        --EndIf:Count = 0
        RETURN
      END
    --EndIf:Count <> 1
  END
--EndIf:Variable Input
--Store Tests Data We want (within the Specified Time Frame) in A Temp Table
CREATE TABLE #Tests(Test_Id BigInt, TimeStamp DateTime, Canceled Bit, Result Varchar(20) NULL, Entry_On DateTime)
--SELECT t.* INTO #Tests FROM Tests t WHERE t.Var_Id = @Var_Id AND t.Result_On BETWEEN @Start_Time AND @End_Time
INSERT INTO #Tests (Test_Id, TimeStamp, Canceled, Result, Entry_On)
    SELECT t.Test_Id, t.Result_On, t.Canceled, t.Result, t.Entry_On
      FROM Tests t
     WHERE t.Var_id = @Var_Id AND t.Result_On > @Start_Time AND t.Result_On <= @End_Time
-- Grab pertinent history data and store them in a temp table. 
-- Test_History.Result_On will be called "TimeStamp"
CREATE TABLE #History(Test_Id BigInt, TimeStamp DateTime, Canceled Bit NULL, Result Varchar(20) NULL, Entry_On DateTime NULL, Entry_By Int NULL)
INSERT INTO #History(Test_Id, TimeStamp, Canceled, Result, Entry_On, Entry_By)
     SELECT h.Test_Id, t.TimeStamp, h.Canceled, h.Result, h.Entry_On, h.Entry_By
       FROM Test_History h
       JOIN #Tests t ON t.Test_Id = h.Test_Id
-- Retrieve the specified information
If @TimeSort = 1  -- Ascending sort by 
  BEGIN
      SELECT h.Test_Id
           , [timestamp] = h.timestamp at time zone @DBTz at time zone @InTimeZone
           , h.Canceled
           , h.Result
           , [Entry_On] = h.Entry_On at time zone @DBTz at time zone @InTimeZone
           , u.Username as "EntryByUser"
           , Data_Type_Id = @Data_Type_Id
        FROM #History h
        LEFT JOIN Users u ON u.User_Id = h.Entry_By
    ORDER BY h.TimeStamp ASC, h.Entry_On ASC
  END
Else
  BEGIN
      SELECT h.Test_Id
           , [timestamp] = h.timestamp at time zone @DBTz at time zone @InTimeZone
           , h.Canceled
           , h.Result
           , [Entry_On] = h.Entry_On at time zone @DBTz at time zone @InTimeZone
           , u.Username as "EntryByUser"
           , Data_Type_Id = @Data_Type_Id
        FROM #History h
        LEFT JOIN Users u ON u.User_Id = h.Entry_By
    ORDER BY h.TimeStamp DESC, h.Entry_On DESC
  END
  --EndIf
DROP TABLE #Tests
DROP TABLE #History
