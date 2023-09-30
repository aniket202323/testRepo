-- DESCRIPTION: spXLA_VarTestHistory combines code in spXLAVariableHistory and its complementary lookups into a single
-- stored procedure. MT/6-11-2002
--
CREATE PROCEDURE dbo.spXLA_VarTestHistory
 	   @Var_Id 	 Integer
 	 , @Var_Desc 	 Varchar(50)
 	 , @Result_On 	 DateTime
 	 , @TimeSort 	 TinyInt = 0
 	 , @InTimeZone 	 varchar(200) = null
AS
Declare @DBTz varchar(100)
Select @DBTz = Value from Site_Parameters where Parm_id = 192
SELECT @Result_On = @Result_On at time zone @InTimeZone at time zone @DBTz 
--SET NOCOUNT ON --commented out because ECR #26008 (mt/8-25-2003)
-- Set Default Sort Order
If @TimeSort Is NULL SELECT @TimeSort = 0
DECLARE @Data_Type_Id Int
DECLARE @Row_Count    Int
-- First Validate Variable Input
SELECT @Row_Count = 0
If @Var_Desc Is NOT NULL 
  BEGIN
    SELECT @Var_Id = v.Var_Id, @Data_Type_Id = v.Data_Type_Id FROM Variables v WHERE v.Var_Desc = @Var_Desc
    SELECT @Row_Count = @@ROWCOUNT
  END
Else If @Var_Id Is NOT NULL
  BEGIN
    SELECT @Var_Desc = v.Var_Desc, @Data_Type_Id = v.Data_Type_Id FROM Variables v WHERE v.Var_Id = @Var_Id
    SELECT @Row_Count = @@ROWCOUNT
  END
Else --Both must be null
  BEGIN
    SELECT ReturnStatus = -20 	 --  "No Variable Specified"
    RETURN
  END
--EndIf:Variable Input
If @Row_Count = 0 
  BEGIN
    SELECT ReturnStatus = -10 	 -- "Variable Specified Not Found"
    RETURN
  END
--EndIf:@Row_Count
If @TimeSort = 0  -- Ascending Sort By "Entry On" Default
  BEGIN
      SELECT
 	  	  	 h.Test_Id
 	  	  	 , [TimeStamp] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , h.Canceled
 	  	  	 , h.Result
 	  	  	 , [Entry_On] = h.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , h.Array_Id
 	  	  	 ,[EntryByUser] = u.Username
 	  	  	 , Data_Type_Id = @Data_Type_Id
        FROM Test_History h 
        JOIN Tests t ON t.Test_Id = h.Test_Id AND t.Result_On = @Result_On AND t.Var_Id = @Var_Id
        JOIN Users u ON u.User_Id = h.Entry_By
    ORDER BY h.Entry_On ASC
  END
Else  -- Descending Sort By "Entry On"
  BEGIN
      SELECT
 	  	  	 h.Test_Id
 	  	  	 , [TimeStamp] = t.Result_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , h.Canceled
 	  	  	 , h.Result
 	  	  	 , [Entry_On] = h.Entry_On at time zone @DBTz at time zone @InTimeZone
 	  	  	 , h.Array_Id
 	  	  	 ,[EntryByUser] = u.Username
 	  	  	 , Data_Type_Id = @Data_Type_Id
        FROM Test_History h 
        JOIN Tests t ON t.Test_Id = h.Test_Id AND t.Result_On = @Result_On AND t.Var_Id = @Var_Id
        JOIN Users u ON u.User_Id = h.Entry_By
    ORDER BY h.Entry_On DESC
  END
--EndIf
