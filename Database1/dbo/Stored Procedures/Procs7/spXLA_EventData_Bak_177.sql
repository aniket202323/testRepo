-- spXLA_EventData() replaces spXLAEventData_New. ECR #25128: mt/3-11-2003: Changed to handle duplicate Var_desc. MSI
-- doesn't enforce unique Var_desc across entire system, must handle via code.
--
CREATE PROCEDURE dbo.[spXLA_EventData_Bak_177]
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
If @Var_Desc Is NULL AND @Var_Id Is NULL
  BEGIN
    SELECT [ReturnStatus] = -35 	  	 --variable NO SPECIFIED
    RETURN
  END
Else If @Var_Desc Is NULL --we have Var_Id
  BEGIN
    SELECT @Var_Desc = v.Var_Desc, @Pu_Id = v.Pu_Id, @Data_Type_Id = v.Data_Type_Id, @Event_Type = v.Event_Type, @MasterUnitId = pu.Master_Unit 
      FROM Variables v 
      JOIN Prod_Units pu  ON pu.Pu_Id = v.Pu_Id  
     WHERE v.Var_Id = @Var_Id
    SELECT @VariableFetchCount = @@ROWCOUNT
    If @VariableFetchCount = 0
      BEGIN
        SELECT [ReturnStatus] = -30 	 --variable NOT FOUND
        RETURN
      END
    --EndIf:count=0
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
          SELECT [ReturnStatus] = -30 	 --variable NOT FOUND
        Else --too many Var_Desc
          SELECT [ReturnStatus] = -33 	 --DUPLICATE FOUND for var_desc
        --EndIf:count
        RETURN
      END
    --EndIf:count<>1
  END
--EndIf: both Var_Id and Var_Desc NULL
If ISNUMERIC(@Data_Type_Id) = 0
  BEGIN 
    SELECT ReturnStatus = -20 	  	 --"Illegal data type"
    RETURN
  END
--EndIf
If @Event_Type = 0 
  BEGIN 
    SELECT ReturnStatus = -40 	  	 --"Variable is not event-based"
    RETURN
  END
--EndIf
If @MasterUnitId Is NOT NULL SELECT @Pu_Id = @MasterUnitId
If @Event_Id Is NOT NULL
  SELECT @Event_Num = e.Event_Num FROM Events e WHERE e.Event_Id = @Event_Id AND e.Pu_Id = @Pu_Id
--EndIf
If @NeedProductJoin = 1 AND @NeedEventStatus = 1
  BEGIN
    SELECT [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
          , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
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
    SELECT [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
         , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
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
    SELECT [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
         , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
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
    SELECT [Result_On] = dbo.fnServer_CmnConvertFromDbTime(t.Result_On,@InTimeZone)
         , [Entry_On] = dbo.fnServer_CmnConvertFromDbTime(t.Entry_On,@InTimeZone)
         , [Result] = Case When @DecimalSep <> '.' AND @Data_Type_Id = 2 Then REPLACE(t.Result, '.', @DecimalSep) Else t.Result End
         , t.canceled
         , t.Comment_Id
         , Data_Type_Id = @Data_Type_Id
      FROM Events e
      LEFT OUTER JOIN Tests t ON t.Result_On = e.TimeStamp AND t.Var_Id = @Var_Id
     WHERE e.Pu_Id = @Pu_Id AND e.Event_Num = @Event_Num
  END
--EndIf
