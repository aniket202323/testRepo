-- spXLA_LastTestsValue replaces spXLALastTestValue_New. ECR #25128: mt/3-11-2003: Changed to handle duplicate Var_desc
-- MSI doesn't enforce unique Var_Desc in the entire system, must handle via code.
--
CREATE Procedure dbo.spXLA_LastTestsValue
 	   @Var_Id 	  	 Integer
 	 , @Var_Desc 	  	 Varchar(50)
 	 , @NeedProductJoin 	 TinyInt 	           -- 1 = Include product join, 0 = exclude
 	 , @NeedEventJoin 	 TinyInt 	           -- 1 = Include Event Status join, 0 = exclude
 	 , @DecimalChar 	  	 Varchar(1) = '.'  -- Comma or Period (Default) for different regional setttings on PC --mt/3-19-2002
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
 	 --Needed for variable-related stuff
DECLARE @Pu_Id 	  	  	 Integer
DECLARE 	 @Prod_Id 	  	 Int
DECLARE @Data_Type_Id  	  	 Integer
DECLARE 	 @Event_Type 	  	 SmallInt
DECLARE 	 @VariableFetchCount  	 Integer
DECLARE 	 @MasterUnitId 	  	 Integer
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
--Set Decimal Separator Default Value, if applicable
If @DecimalChar Is NULL SELECT @DecimalChar = '.'
SELECT @Data_Type_Id  	  	 = -1
SELECT @MasterUnitId 	  	 = -1
SELECT @Pu_Id  	  	  	 = -1
SELECT @Event_Type 	  	 = -1
SELECT @VariableFetchCount  	 = 0
--Verify variable information and get required information
If @Var_Desc Is NULL AND @Var_ID Is NULL
  BEGIN
    SELECT [ReturnStatus] = -35 	  	 --no var_Id, no Var_desc NOT SPECIFIED
    RETURN
  END
Else If @Var_Desc Is NULL --we have Var_Id
  BEGIN
    SELECT @Var_Desc = v.Var_Desc, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, @MasterUnitId = pu.Master_Unit 
      FROM Variables v 
      JOIN Prod_Units pu ON pu.Pu_Id = v.Pu_Id  
     WHERE v.Var_Id = @Var_Id
    SELECT @VariableFetchCount = @@ROWCOUNT
    If @VariableFetchCount = 0
      BEGIN
        SELECT [ReturnStatus] = -30 	 --variable NOT FOUND
        RETURN
      END
    --EndIf:count =0
  END
Else --we have @Var_Desc
  BEGIN
    SELECT @Var_Id = v.Var_Id, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, @MasterUnitId = pu.Master_Unit 
      FROM Variables v
      JOIN Prod_Units pu  on pu.Pu_Id = v.Pu_Id
     WHERE v.Var_Desc = @Var_Desc
    SELECT @VariableFetchCount = @@ROWCOUNT
    If @VariableFetchCount <> 1
      BEGIN
        If @VariableFetchCount = 0
          SELECT [ReturnStatus] = -30 	 --variable specified NOT FOUND
        Else --too many var_Desc
          SELECT [ReturnStatus] = -33 	 --DUPLICATE FOUND for var_desc
        --EndIf:count
        RETURN
      END
    --EndIf:Count<> 1
  END
--EndIf:Both Var_Id and Var_Desc NULL
If @MasterUnitId Is NOT NULL SELECT @Pu_Id = @MasterUnitId
SELECT @Event_Type = Case @Event_Type When 0 Then 0 Else 1 End
If ISNUMERIC(@Data_Type_Id) = 0
  BEGIN 
    SELECT ReturnStatus = -20 	  	 --"Illegal data type"
    RETURN
  END
--EndIf
DECLARE @MyTests Table(Canceled Bit,Result_On DateTime,Entry_On DateTime,Comment_Id Int,Result VarChar(25))
Insert Into @MyTests(Canceled,Result_On,Entry_On,Comment_Id,Result)
SELECT Top 1 Canceled,Result_On,Entry_On,Comment_Id,Result 
      FROM Tests t
     WHERE t.Var_Id = @Var_Id
  ORDER BY t.Result_On DESC
--Making Regionally compatible decimal separator
UPDATE @MyTests
  SET Result = CASE WHEN @DecimalChar <> '.' AND @Data_Type_Id = 2 THEN REPLACE(Result, '.', @DecimalChar) ELSE Result END
If @NeedProductJoin = 1 AND @NeedEventJoin = 1
  BEGIN
    SELECT  	 
 	  	 [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	 , t.Canceled
 	  	 , t.Comment_Id
 	  	 , t.Result
 	  	 , p.Prod_Code
 	  	 , e.Event_Id
 	  	 , e.Event_Num
 	  	 , Event_Status = s.ProdStatus_Desc
 	  	 , Data_Type_Id = @Data_Type_Id
 	  	 , Event_Type = @Event_Type
 	  	 , Pu_Id = @Pu_Id
      FROM @MyTests t
      LEFT OUTER JOIN Production_Starts ps ON ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)       AND ps.Pu_Id = @Pu_Id
      LEFT OUTER JOIN Products p ON p.Prod_Id = ps.Prod_Id
      LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
      LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
  END
Else If @NeedProductJoin = 1 AND @NeedEventJoin = 0
  BEGIN
    SELECT  	  	 
 	  	 [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	 , t.Canceled
 	  	 , t.Comment_Id
 	  	 , t.Result
 	  	 , p.Prod_Code
 	  	 , Data_Type_Id = @Data_Type_Id
 	  	 , Event_Type = @Event_Type
 	  	 , Pu_Id = @Pu_Id
      FROM @MyTests t
      LEFT OUTER JOIN Production_Starts ps ON ps.Start_Time <= t.Result_On AND (ps.End_Time > t.Result_On OR ps.End_Time Is NULL)
       AND ps.Pu_Id = @Pu_Id
      LEFT OUTER JOIN Products p ON p.Prod_Id = ps.Prod_Id
  END
Else If @NeedProductJoin = 0 AND @NeedEventJoin = 1
  BEGIN
    SELECT 
     	 [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	 , t.Canceled
 	  	 , t.Comment_Id
 	  	 , t.Result
 	  	 , e.Event_Id
 	  	 , e.Event_Num
 	  	 , Event_Status = s.ProdStatus_Desc
 	  	 , Data_Type_Id = @Data_Type_Id
 	  	 , Event_Type = @Event_Type
 	  	 , Pu_Id = @Pu_Id
      FROM @mytests t
      LEFT OUTER JOIN Events e ON e.TimeStamp = t.Result_On AND e.Pu_Id = @Pu_Id
      LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status
  END
Else If @NeedProductJoin = 0 AND @NeedEventJoin = 0
  BEGIN
    SELECT 
     	 [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	 , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	 , t.Canceled
 	  	 , t.Comment_Id
 	  	 , t.Result
 	  	 , Data_Type_Id = @Data_Type_Id
 	  	 , Event_Type = @Event_Type
 	  	 , Pu_Id = @Pu_Id
      FROM @MyTests t
  END
--EndIf
