-- spXLAEventData_New() replaces spXLAEventData_Expand. Changes are:
-- (1) spXLAEventData_New accepts variable as ID or Description
-- (2) spXLAEventData_New does internal lookups for needed information. Add-In no longer has to lookup any before or after
--     the call to spXLAEventData_New
--
-- mt/1-17-2002
--
CREATE PROCEDURE dbo.spXLAEventData_New
 	   @Var_Id 	  	 Integer
 	 , @Var_Desc 	  	 Varchar(50)
 	 , @Event_Id 	  	 Integer
 	 , @Event_Num  	  	 varchar(50)
 	 , @NeedProductJoin 	 TinyInt 	  	  	 --1 = include join for product code; 0 = exclude it
 	 , @NeedEventStatus 	 TinyInt 	  	  	 --1 = include join to get Event_Status; 0 = exclude it
 	 , @DecimalSep 	  	 varchar(1)= NULL 	 --Added:MT/4-9-2002
 	 , @InTimeZone 	 varchar(200) = null
AS
DECLARE @Pu_Id 	  	  	 Integer
DECLARE @Data_Type_Id 	  	 Integer
DECLARE @Event_Type 	  	 SmallInt
DECLARE @MasterUnitId 	  	 Integer
DECLARE @VariableFetchCount 	 Integer
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
SELECT @Data_Type_Id  	  	 = -1
SELECT @MasterUnitId 	  	 = -1
SELECT @Pu_Id  	  	  	 = -1
SELECT @Event_Type 	  	 = -1
SELECT @VariableFetchCount  	 = 0
If @DecimalSep Is NULL SELECT @DecimalSep = '.' 
If @Var_Desc Is NULL
  BEGIN
    SELECT @Var_Desc = v.Var_Desc, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, @MasterUnitId = pu.Master_Unit 
      FROM Variables v 
      JOIN Prod_Units pu  ON pu.Pu_Id = v.Pu_Id  
     WHERE v.Var_Id = @Var_Id
    SELECT @VariableFetchCount = @@ROWCOUNT
  END
Else --@Var_Desc NOT null, use it
  BEGIN
    SELECT @Var_Id = v.Var_Id, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, @MasterUnitId = pu.Master_Unit 
      FROM Variables v
      JOIN Prod_Units pu on pu.Pu_Id = v.Pu_Id
     WHERE v.Var_Desc = @Var_Desc
    SELECT @VariableFetchCount = @@ROWCOUNT
  END
--EndIf
If @VariableFetchCount = 0 
  BEGIN
    SELECT ReturnStatus = -10 	  	 --Indicates to Add-In "Variable specified not found"
    RETURN
  END
--EndIf
If ISNUMERIC(@Data_Type_Id) = 0
  BEGIN 
    SELECT ReturnStatus = -20 	  	 --"Illegal data type"
    RETURN
  END
--EndIf
If @Event_Type = 0 
  BEGIN 
    SELECT ReturnStatus = -30 	  	 --"Variable is not event-based"
    RETURN
  END
--EndIf
If @MasterUnitId Is NOT NULL SELECT @Pu_Id = @MasterUnitId
If @Event_Id Is NOT NULL
  SELECT @Event_Num = e.Event_Num FROM Events e WHERE e.Event_Id = @Event_Id AND e.Pu_Id = @Pu_Id
--EndIf
--RETRIEVE ResultSet
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
If @NeedProductJoin = 1 AND @NeedEventStatus = 1
  BEGIN
    SELECT [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
          , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
          , [Result] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Result, '.', @DecimalSep) Else t.Result End
          , t.canceled
          , t.Comment_Id
          , p.Prod_Code
          , Event_Status = s.ProdStatus_Desc
          , Data_Type_Id = @Data_Type_Id
      FROM Events e
      LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status 
      LEFT OUTER JOIN Tests t ON t.Result_On = e.TimeStamp AND t.Var_Id = @Var_Id
      LEFT OUTER JOIN Production_Starts ps ON ps.Start_Time <= e.TimeStamp AND (ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL)
       AND ps.Pu_Id = e.Pu_Id
      JOIN Products p ON p.Prod_Id = ps.Prod_Id
     WHERE e.Pu_Id = @Pu_Id AND e.Event_Num = @Event_Num
  END
Else If @NeedProductJoin = 1 AND @NeedEventStatus = 0
  BEGIN
    SELECT [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
         , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
         , [Result] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Result, '.', @DecimalSep) Else t.Result End
         , t.canceled
         , t.Comment_Id
         , p.Prod_Code
         , Data_Type_Id = @Data_Type_Id
      FROM Events e
      LEFT OUTER JOIN Tests t ON t.Result_On = e.TimeStamp AND t.Var_Id = @Var_Id
      LEFT OUTER JOIN Production_Starts ps ON ps.Start_Time <= e.TimeStamp AND (ps.End_Time > e.TimeStamp OR ps.End_Time Is NULL)
       AND ps.Pu_Id = e.Pu_Id
      JOIN Products p ON p.Prod_Id = ps.Prod_Id
     WHERE e.Pu_Id = @Pu_Id AND e.Event_Num = @Event_Num
  END
Else If @NeedProductJoin = 0 AND @NeedEventStatus = 1
  BEGIN
    SELECT [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
         , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
         , [Result] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Result, '.', @DecimalSep) Else t.Result End
         , t.canceled
         , t.Comment_Id
         , Event_Status = s.ProdStatus_Desc
         , Data_Type_Id = @Data_Type_Id
      FROM Events e
      LEFT OUTER JOIN Production_Status s ON s.ProdStatus_Id = e.Event_Status 
      LEFT OUTER JOIN Tests t ON t.Result_On = e.TimeStamp AND t.Var_Id = @Var_Id
     WHERE e.Pu_Id = @Pu_Id AND e.Event_Num = @Event_Num
  END
Else --If @NeedProductJoin = 0 AND @NeedEventStatus = 0
  BEGIN
    SELECT [Result_On] = t.Result_On at time zone @DBTz at time zone @InTimeZone
         , [Entry_On] = t.Entry_On at time zone @DBTz at time zone @InTimeZone
         , [Result] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Result, '.', @DecimalSep) Else t.Result End
         , t.canceled
         , t.Comment_Id
         , Data_Type_Id = @Data_Type_Id
      FROM Events e
      LEFT OUTER JOIN Tests t ON t.Result_On = e.TimeStamp AND t.Var_Id = @Var_Id
     WHERE e.Pu_Id = @Pu_Id AND e.Event_Num = @Event_Num
  END
--EndIf
