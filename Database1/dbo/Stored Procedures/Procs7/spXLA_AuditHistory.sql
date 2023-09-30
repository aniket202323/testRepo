-- DESCRIPTION: spXLA_AuditHistory replaces spXLA_VarTestHistory. ECR #25128: mt/3-11-2003: Changed to handle duplicate Var_Desc.
-- MSI doesn't enforce unique Var_desc in the entire GBDB.
--
-- ECR #27300 (mt/1-20-2004): Fix incorrect alias for "history" timestamp. TimeStamp should come from Test_History table "h"
-- ECR #27300 (mt/6-18-2004) undo the change. Test_History.Result_On is nullable field, Tests.Result_On is not nullable, use this field instead.
--
CREATE PROCEDURE dbo.spXLA_AuditHistory 
 	   @Var_Id 	 Integer
 	 , @Var_Desc 	 Varchar(50)
 	 , @Result_On 	 DateTime
 	 , @TimeSort 	 TinyInt = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Result_On = @Result_On at time zone @InTimeZone at time zone @DBTz 
-- Set Default Sort Order
If @TimeSort Is NULL SELECT @TimeSort = 0
DECLARE @Data_Type_Id Int
DECLARE @Row_Count    Int
-- First Validate Variable Input
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
If @TimeSort = 1 	 --'0  -- 1= Ascending Sort By "Entry On" Default
  BEGIN
      SELECT h.Test_Id
           , [TimeStamp] = t.Result_On at time zone @DBTz at time zone @InTimeZone
          , h.Canceled
           , h.Result
           , [Entry_On] = h.Entry_On at time zone @DBTz at time zone @InTimeZone
           , h.Array_Id
           , [EntryByUser] = u.Username 
           , Data_Type_Id = @Data_Type_Id
        FROM Test_History h 
        JOIN Tests t ON t.Test_Id = h.Test_Id AND t.Result_On = @Result_On AND t.Var_Id = @Var_Id
        LEFT JOIN Users u ON u.User_Id = h.Entry_By 	 --added LEFT h.Enty_By is Nullable; mt/1-20-2004
    ORDER BY h.Entry_On ASC, h.Result_On ASC
  END
Else  -- Descending Sort By "Entry On"
  BEGIN
      SELECT h.Test_Id
           , [TimeStamp] =  t.Result_On at time zone @DBTz at time zone @InTimeZone
           , h.Canceled
           , h.Result
           , [Entry_On] = h.Entry_On at time zone @DBTz at time zone @InTimeZone
           , h.Array_Id
           , [EntryByUser] = u.Username 
           , Data_Type_Id = @Data_Type_Id
        FROM Test_History h 
        JOIN Tests t ON t.Test_Id = h.Test_Id AND t.Result_On = @Result_On AND t.Var_Id = @Var_Id
        LEFT JOIN Users u ON u.User_Id = h.Entry_By 	 --added LEFT h.Enty_By is Nullable; mt/1-20-2004
    ORDER BY h.Entry_On DESC, h.Result_On DESC
  END
--EndIf
