Create Procedure dbo.spAL_TestHistory
  @Test_Id BigInt,
  @DecimalSep char(1) = '.'
 AS
--JG Added this for regional settings:
--  Must replace the period in the result value with a comma if the 
--  passed decimal separator is not a period.
Select @DecimalSep = COALESCE(@DecimalSep,'.')
DECLARE @DataType 	  	 Int
SELECT @DataType = Data_Type_Id 
  FROM Variables v
  JOIN Tests t on t.Var_Id = v.Var_Id and Test_Id = @Test_Id
--JG END
  -- Get our test history data.
  SELECT t.Canceled,
--         t.Result,
          Result = CASE 
                        WHEN @DecimalSep <> '.' and @DataType = 2 THEN REPLACE(T.Result, '.', @DecimalSep)
                        ELSE T.Result
                      END,
         t.Entry_On,
         Entry_By = u.username,
         Second_UserName = u2.username
  FROM Test_History t
  JOIN Users u ON u.user_id = t.entry_by
  Left outer Join ESignature e on e.Signature_Id = t.Signature_Id
  Left outer Join Users u2 on u2.User_Id = e.Verify_User_Id
  WHERE t.Test_Id = @Test_ID and entry_by <> 5
  ORDER BY Entry_On DESC
